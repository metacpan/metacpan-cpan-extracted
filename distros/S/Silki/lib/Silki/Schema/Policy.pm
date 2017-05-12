package Silki::Schema::Policy;
{
  $Silki::Schema::Policy::VERSION = '0.29';
}

use strict;
use warnings;

use DateTime::Format::Pg;
use Encode qw( decode );
use Lingua::EN::Inflect qw( PL_N );
use Scalar::Util qw( blessed );

use Fey::ORM::Policy;

#<<<
transform_all
    matching { $_[0]->name() =~ /_datetime$/ }
    => deflate {
        blessed $_[1] && $_[1]->isa('DateTime')
            ? DateTime::Format::Pg->format_datetime( $_[1] )
            : $_[1];
    }
    => inflate {
        return $_[1] unless defined $_[1];
        my $dt = DateTime::Format::Pg->parse_datetime( $_[1] );
        $dt->set_time_zone('UTC');
        return $dt;
    };
#>>>
#<<<
transform_all
    matching { $_[0]->name() =~ /_date$/ } =>
    deflate {
        blessed $_[1] && $_[1]->isa('DateTime')
            ? DateTime::Format::Pg->format_date( $_[1] )
            : $_[1];
    }
    => inflate {
        return $_[1] unless defined $_[1];
        my $dt = DateTime::Format::Pg->parse_date( $_[1] );
        $dt->set_time_zone('UTC');
        return $dt;
    };
#>>>
# This is a hack that should not be necessary, but DBD::Pg has a fixed list of
# column types it will treat as utf-8, and user-defined types are not
# included. See https://rt.cpan.org/Ticket/Display.html?id=40199 for details.
my %text_types = map { $_ => 1 } qw( citext email_address filename );
#<<<
transform_all
    matching { $text_types{ lc $_[0]->type() } } =>
    inflate {
        return decode( 'utf-8', $_[1] );
    };
#>>>
has_one_namer {
    my $name = $_[0]->name();
    my @parts = map {lc} ( $name =~ /([A-Z][a-z]+)/g );

    return join q{_}, @parts;
};

has_many_namer {
    my $name = $_[0]->name();
    my @parts = map {lc} ( $name =~ /([A-Z][a-z]+)/g );

    $parts[-1] = PL_N( $parts[-1] );

    return join q{_}, @parts;
};

1;

# ABSTRACT: A Fey::Policy for Silki

__END__
=pod

=head1 NAME

Silki::Schema::Policy - A Fey::Policy for Silki

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

