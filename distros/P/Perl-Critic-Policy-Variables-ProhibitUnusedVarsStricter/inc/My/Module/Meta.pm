package My::Module::Meta;

use 5.006001;

use strict;
use warnings;

use Carp;

use Exporter qw{ import };

our $VERSION = '0.105';

our @EXPORT_OK = qw{
    meta_merge
    build_required_module_versions
    required_module_versions
    requires_perl
    recommended_module_versions
};

sub meta_merge {
    return {
	'meta-spec'	=> {
	    version	=> 2,
	},
#       homepage    => 'http://perlcritic.com',
	no_index	=> {
            file        => [
                qw<
                    TODO.pod
                >
            ],
            directory   => [
                qw<
                    doc
                    examples
                    inc
                    tools
                    xt
                >
            ],
	},
	resources	=> {
	    bugtracker	=> {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-Policy-Variables-ProhibitUnusedVarsStricter',
##                mailto  => 'wyant@cpan.org',
            },
	    license	=> 'http://dev.perl.org/licenses/',
	    repository	=> {
		type	=> 'git',
		url	=> 'git://github.com/trwyant/perl-Perl-Critic-Policy-Variables-ProhibitUnusedVarsStricter.git',
		web	=> 'https://github.com/trwyant/perl-Perl-Critic-Policy-Variables-ProhibitUnusedVarsStricter',
	    },
#            MailingList => 'http://perlcritic.tigris.org/servlets/SummarizeList?listName=users',
	}
    };
}

sub required_module_versions {
    my @args = @_;
    return (
        'base'                      => 0,
        'strict'                    => 0,
        'warnings'                  => 0,
        'Perl::Critic::Document'    => 1.119,   # need 1.119 here
        'Perl::Critic::Policy'      => 1.119,
        'Perl::Critic::Utils'       => 1.119,
        'PPI::Token::Symbol'        => 0,
        'PPIx::QuoteLike'           => 0.005,
        'Readonly'                  => 0,
        'Scalar::Util'              => 0,
        @args,
    );
}

sub build_required_module_versions {
    return (
        'lib'       => 0,
        'Carp'      => 0,
    );
}

sub recommended_module_versions {
    return (
        'File::Which'   => 0,
    );
}

sub requires_perl {
    return '5.006001';
}


1;

__END__

=head1 NAME

My::Module::Meta - Metadata for the current module

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Meta qw{ recommended_module_versions };

=head1 DESCRIPTION

This Perl module holds metadata for the current module. It is private to
the current module.

=head1 SUBROUTINES

No subroutines are exported by default, but the following subroutines
are exportable:

=head2 build_required_module_versions

This subroutine returns an array of the names and versions of modules
required for the build.

=head2 meta_merge

 use YAML;
 print Dump( $meta->meta_merge() );

This method returns a reference to a hash describing the meta-data which
has to be provided by making use of the builder's C<meta_merge>
functionality. This includes the C<dynamic_config>, C<no_index> and
C<resources> data.

=head2 recommended_module_versions

This subroutine returns an array of the names and versions of
recommended modules.

=head2 required_module_versions

This subroutine returns an array of the names and versions of required
modules. Any arguments will be appended to the returned list.

=head2 requires_perl

This subroutine returns the version of Perl required by the module.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2020 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 72
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=72 ft=perl expandtab shiftround :

