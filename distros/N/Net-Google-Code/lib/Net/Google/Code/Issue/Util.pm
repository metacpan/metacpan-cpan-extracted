use strict;
use warnings;

package Net::Google::Code::Issue::Util;
use Net::Google::Code::Role::HTMLTree;

use DateTime;
use XML::TreePP;
my $tpp = XML::TreePP->new;
$tpp->set( output_encoding => 'UTF-8' );
$tpp->set( utf8_flag => 1 );

sub write_xml {
    my $self = shift;
    return $tpp->write(shift);
}


sub translate_from_xml {
    my $class = shift;
    my $ref = shift;
    return unless $ref;
    my %args = @_;
    die "invalid type: $args{type}" unless $args{type} =~ /^(issue|comment)$/;
    %$ref =
      map { my $new = $_; $new =~ s/^issues://g; $new => $ref->{$_} }
      keys %$ref;

    for my $k ( keys %$ref ) {
        if ( $k eq 'id' ) {
            if ( $args{type} eq 'issue' ) {
                $ref->{id} = $1 if $ref->{id} =~ /(\d+)$/;
            }
            elsif ( $args{type} eq 'comment' ) {
                $ref->{sequence} = $1 if $ref->{id} =~ /(\d+)$/;
                delete $ref->{id};
            }
        }
        if ( $k eq 'title' ) {
            if ( $args{type} eq 'issue' ) {
                $ref->{summary} = $ref->{$k};
                delete $ref->{$k};
            }
        }
        if ( $k eq 'author' ) {
            if ( $args{type} eq 'issue' ) {
                $ref->{reporter} = $ref->{$k}->{name};
                delete $ref->{author};
            }
            elsif ( $args{type} eq 'comment' ) {
                $ref->{author} = $ref->{$k}->{name};
            }
        }
        elsif ( $k eq 'content' ) {
            my $text;
            if ( $ref->{$k}{-type} eq 'html' ) {
                my $tree =
                  Net::Google::Code::Role::HTMLTree->html_tree( html => '<pre>'
                      . ( $ref->{$k}->{'#text'} || '' )
                      . '</pre>' );
                $text = $tree->as_text if $tree;
                $tree->delete;
            }
            else {
                $text = $ref->{$k}->{'#text'};
            }

            $text =~ s/\s+$// if $text;

            if ( $args{type} eq 'issue' ) {
                $ref->{description} = $text;
                delete $ref->{$k};
            }
            elsif ( $args{type} eq 'comment' ) {
                $ref->{content} = $text;
            }
        }
        elsif ( $k eq 'published' ) {
            if ( $args{type} eq 'issue' ) {
                $ref->{reported} = $class->datetime_from_string( $ref->{$k} );
            }
            elsif ( $args{type} eq 'comment' ) {
                $ref->{date} = $class->datetime_from_string( $ref->{$k} );
            }
        }
        elsif ( $k eq 'updated' ) {
            $ref->{$k} = $class->datetime_from_string( $ref->{$k} );
        }
        elsif ( $k eq 'owner' ) {
            my $tmp   = {};
            my $value = $ref->{$k};
            $ref->{$k} = $value->{'issues:username'};
        }
        elsif ( $k eq 'cc' ) {
            my @cc = ref $ref->{$k} eq 'ARRAY' ? @{ $ref->{$k} } : $ref->{$k};
            $ref->{$k} = [];
            for my $cc (@cc) {
                push @{$ref->{$k}}, $cc->{'issues:username'};
            }
        }
        elsif ( $k eq 'label' ) {
            $ref->{labels} =
              ref $ref->{$k} eq 'ARRAY' ? $ref->{$k} : [ $ref->{$k} ];
            delete $ref->{label};
        }
        elsif ( $k eq 'updates' ) {
            my $tmp   = {};
            my $value = $ref->{updates};
            for my $k ( keys %$value ) {
                my $v = $value->{$k};
                $k =~ s/^issues://;
                $k .= 's' if $k eq 'label';
                $k =~ s/Update$//;
                $tmp->{$k} = $v;
            }
            if ( exists $tmp->{labels} && !ref $tmp->{labels} ) {
                $tmp->{labels} = [ $tmp->{labels} ];
            }
            $ref->{$k} = $tmp;
        }
    }
    return $ref;
}

sub translate_to_xml {
    my $self = shift;
    my $ref  = shift;
    my %args = @_;

    my %entry;
    if ( $args{type} eq 'create' ) {
        for my $key ( keys %$ref ) {
            if ( $key eq 'author' ) {
                $entry{'author'}{'name'} = $ref->{$key};
            }
            elsif ( $key eq 'comment' ) {
                $entry{'content'} = $ref->{$key};
            }
            elsif ( $key eq 'summary' ) {
                $entry{'title'} = $ref->{$key};
            }
            elsif ( $key eq 'cc' ) {
                $entry{'issues:cc'}{'issues:username'} = $ref->{$key};
            }
            elsif ( $key eq 'owner' ) {
                $entry{'issues:owner'}{'issues:username'} = $ref->{$key};
            }
            elsif ( $key eq 'labels' ) {
                $entry{'issues:label'} = $ref->{$key};
            }
            else {
                $entry{"issues:$key"} = $ref->{$key};
            }
        }
    }
    elsif ( $args{type} eq 'update' ) {
        for my $key ( keys %$ref ) {
            if ( $key eq 'author' ) {
                $entry{'author'}{'name'} = $ref->{$key};
            }
            elsif ( $key eq 'comment' ) {
                $entry{'content'} = $ref->{$key};
            }
            elsif ( $key eq 'cc' ) {
                $entry{'issues:updates'}{'issues:ccUpdate'} = $ref->{$key};
            }
            elsif ( $key eq 'owner' ) {
                $entry{'issues:updates'}{'issues:ownerUpdate'} = $ref->{$key};
            }
            elsif ( $key eq 'labels' ) {
                $entry{'issues:updates'}{'issues:label'} = $ref->{$key};
            }
            else {
                $entry{'issues:updates'}{"issues:$key"} = $ref->{$key};
            }
        }
    }
    else {
        die "invalid type: $args{type}";
    }

    $ref = { entry => \%entry };
    my $xml = Net::Google::Code::Issue::Util->write_xml($ref);
    $xml =~
s!<entry>!<entry xmlns='http://www.w3.org/2005/Atom' xmlns:issues='http://schemas.google.com/projecthosting/issues/2009'>!;
    return $xml;
}

sub datetime_from_string {
    my $class  = shift;
    my $string = shift;
    return unless $string;
    if ( $string =~
        /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.000)?(Z|[+-]\d{2}:\d{2})/ )
    {

        #    2009-06-01T13:00:10Z
        my $dt = DateTime->new(
            year      => $1,
            month     => $2,
            day       => $3,
            hour      => $4,
            minute    => $5,
            second    => $6,
            time_zone => $7 eq 'Z' ? 'UTC' : $7,
        );
        $dt->set_time_zone( 'UTC' );
    }
}

1;

__END__

=head1 NAME

Net::Google::Code::Issue::Util - Util

=head1 SYNOPSIS

    use Net::Google::Code::Issue::Util;

=head1 DESCRIPTION

utility methods live here

=head1 INTERFACE

=over 4

=item write_xml

wrap of XML::TreePP->write

=item translate_from_xml( $hashref | $xml_string )

translate from xml, the general translation map is:
'issues:stars' => 'stars',
value datetime string => L<DateTime> object

=item translate_to_xml( $hashref, root => 'project', boolean => ['foo','bar'] )

generally, the reverse of translate_from_xml.

=item datetime_from_string

parse string to a L<DateTime> object, and translate its timezone to UTC

=back

=head1 SEE ALSO

L<DateTime>

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

