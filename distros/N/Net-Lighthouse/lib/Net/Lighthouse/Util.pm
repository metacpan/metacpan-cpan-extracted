use strict;
use warnings;

package Net::Lighthouse::Util;
use DateTime;
use XML::TreePP;
my $tpp = XML::TreePP->new;
$tpp->set( xml_decl => '' );
$tpp->set( output_encoding => 'UTF-8' );
$tpp->set( utf8_flag => 1 );
$tpp->set( text_node_key => 'content' );

BEGIN {
    local $@;
    eval { require YAML::Syck; };
    if ($@) {
        require YAML;
        *_Load     = *YAML::Load;
    }
    else {
        *_Load     = *YAML::Syck::Load;
    }
}

sub read_xml {
    my $self = shift;
    return $tpp->parse( shift );
}

sub write_xml {
    my $self = shift;
    return $tpp->write(shift);
}


sub translate_from_xml {
    my $class = shift;
    my $ref = shift;
    return unless $ref;
    $ref = Net::Lighthouse::Util->read_xml( $ref ) unless ref $ref;

    # remove root
    if ( keys %$ref == 1 ) {
        ($ref) = values %$ref;
    }

    %$ref = map { my $new = $_; $new =~ s/-/_/g; $new => $ref->{$_} } keys %$ref;
    for my $k ( keys %$ref ) {
        $ref->{$k} = '' unless $ref->{$k};
        if ( ref $ref->{$k} eq 'HASH' ) {
            if ( $ref->{$k}{-nil} && $ref->{$k}{-nil} eq 'true' ) {
                $ref->{$k} = undef;
            }
            elsif ( $ref->{$k}{-type} && $ref->{$k}{-type} eq 'boolean' ) {
                if ( $ref->{$k}{content} eq 'true' ) {
                    $ref->{$k} = 1;
                }
                else {
                    $ref->{$k} = 0;
                }
            }
            elsif ( $ref->{$k}{-type} && $ref->{$k}{-type} eq 'datetime' ) {
                    $ref->{$k} =
                      $class->datetime_from_string( $ref->{$k}{content} );
            }
            elsif ( $ref->{$k}{-type} && $ref->{$k}{-type} eq 'yaml' ) {
                    $ref->{$k} = _Load( $ref->{$k}{content} );
            }
            elsif ( $ref->{$k}{-type} && $ref->{$k}{-type} eq 'integer' ) {
                if ( defined $ref->{$k}{content} && $ref->{$k}{content} ne '' ) {
                    $ref->{$k} = $ref->{$k}{content};
                }
                else {
                    $ref->{$k} = undef;
                }
            }
            elsif ( defined $ref->{$k}{content} ) {
                $ref->{$k} = $ref->{$k}{content};
            }
            elsif ( keys %{ $ref->{$k} } == 0
                || keys %{ $ref->{$k} } == 1 && exists $ref->{$k}{-type} )
            {
                $ref->{$k} = '';
            }
        }
    }
    return $ref;
}

sub translate_to_xml {
    my $self = shift;
    my $ref  = shift;
    my %args = @_;

    my %normal = map { $_ => 1 } keys %$ref;

    if ( $args{boolean} ) {
        for my $boolean ( @{ $args{boolean} } ) {
            delete $normal{$_};
            next unless exists $ref->{$boolean};
            if ( $ref->{$boolean} ) {
                $ref->{$boolean} = { content => 'true', -type => 'boolean' };
            }
            else {
                $ref->{$boolean} = { content => 'false', -type => 'boolean' };
            }
        }
    }

    for my $normal ( keys %normal ) {
        next unless exists $ref->{$normal};
        $ref->{$normal} = { content => $ref->{$normal} };
    }

    $ref = { $args{root} => $ref } if $args{root};
    return Net::Lighthouse::Util->write_xml($ref);
}

sub datetime_from_string {
    my $class  = shift;
    my $string = shift;
    return unless $string;
    if ( $string =~
        /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(Z|[+-]\d{2}:\d{2})/ )
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

Net::Lighthouse::Util - Util

=head1 SYNOPSIS

    use Net::Lighthouse::Util;

=head1 DESCRIPTION

utility methods live here

=head1 INTERFACE

=over 4

=item translate_from_xml( $hashref | $xml_string )

translate from xml, the general translation map is:
'foo-bar' => 'foo_bar',
value bool false | true => 0 | 1,
value yaml string => object
value datetime string => L<DateTime> object

=item translate_to_xml( $hashref, root => 'project', boolean => ['foo','bar'] )

generally, the reverse of translate_from_xml.

=item read_xml write_xml

wrap of XML::TreePP->parse and XML::TreePP->write, respectively

=item datetime_from_string

parse string to a L<DateTime> object, and translate its timezone to UTC

=back

=head1 SEE ALSO

L<DateTime>, L<YAML::Syck>

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

