package Silki::I18N;
{
  $Silki::I18N::VERSION = '0.29';
}

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw( loc );

use Data::Localize;
use Path::Class qw( file );
use Silki::Config;

{
    my $DL = Data::Localize->new( fallback_languages => ['en'] );
    $DL->add_localizer(
        class      => '+Silki::Localize::Gettext',
        path       => file( Silki::Config->instance()->share_dir, 'i18n', '*.po' ),
        keep_empty => 1,
    );

    sub SetLanguage {
        shift;
        $DL->set_languages(@_);
    }

    sub Language {
        shift;
        ( $DL->languages )[0];
    }

    sub loc {
        $DL->localize(@_);
    }
}

1;

# ABSTRACT: The primary interface to i18n

__END__
=pod

=head1 NAME

Silki::I18N - The primary interface to i18n

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

