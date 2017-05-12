package MooX::ConfigFromFile;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.007';

my %loaded_configs;

sub import
{
    my ( undef, %import_options ) = @_;
    my $target = caller;
    my @target_isa;
    { no strict 'refs'; @target_isa = @{"${target}::ISA"} };

    #don't add this to a role
    #ISA of a role is always empty !
    ## no critic qw/ProhibitStringyEval/
    @target_isa or return;

    my $apply_modifiers = sub {
        return if $target->can('_initialize_from_config');
        my $with = $target->can('with');
        $with->('MooX::ConfigFromFile::Role');
    };
    $apply_modifiers->();

    my $around;
    defined $import_options{config_singleton} and $import_options{config_singleton} and do
    {
        $around = $target->can('around');
        $around->(
            _build_loaded_config => sub {
                my $orig  = shift;
                my $class = shift;
                defined $loaded_configs{$class} or $loaded_configs{$class} = $class->$orig(@_);
                return $loaded_configs{$class};
            }
        );
    };

    my %default_modifiers = (
        config_prefix               => '_build_config_prefix',
        config_identifier           => '_build_config_identifier',
        config_prefix_map_separator => '_build_config_prefix_map_separator',
        config_extensions           => '_build_config_extensions',
        config_dirs                 => '_build_config_dirs',
        config_files                => '_build_config_files',
    );

    foreach my $opt_key ( keys %default_modifiers )
    {
        exists $import_options{$opt_key} or next;
        $around or $around = $target->can('around');
        $around->( $default_modifiers{$opt_key} => sub { $import_options{$opt_key} } );
    }

    return;
}

=head1 NAME

MooX::ConfigFromFile - Moo eXtension for initializing objects from config file

=head1 SYNOPSIS

   package Role::Action;

   use Moo::Role;

   has operator => ( is => "ro" );

   package Action;

   use Moo;
   use MooX::ConfigFromFile; # imports the MooX::ConfigFromFile::Role

   with "Role::Action";

   sub operate { return say shift->operator; }

   package OtherAction;

   use Moo;

   with "Role::Action", "MooX::ConfigFromFile::Role";

   sub operate { return warn shift->operator; }

   package QuiteOtherOne;

   use Moo;

   # consumes the MooX::ConfigFromFile::Role but load config only once
   use MooX::ConfigFromFile config_singleton => 1;

   with "Role::Action";

   sub _build_config_prefix { "die" }

   sub operate { return die shift->operator; }

   package main;

   my $action = Action->new(); # tries to find a config file in config_dirs and loads it
   my $other = OtherAction->new( config_prefix => "warn" ); # use another config file
   my $quite_o = QuiteOtherOne->new(); # quite another way to have an individual config file

=head1 DESCRIPTION

This module is intended to easy load initialization values for attributes
on object construction from an appropriate config file. The building is
done in L<MooX::ConfigFromFile::Role> - using MooX::ConfigFromFile ensures
the role is applied.

For easier usage, with 0.004, several options can be passed via I<use> resulting
in default initializers for appropriate role attributes:

=over 4

=item C<config_prefix>

Default for L<MooX::ConfigFromFile::Role/config_prefix>.

=item C<config_prefix_map_separator>

Default for L<MooX::ConfigFromFile::Role/config_prefix_map_separator>.

=item C<config_extensions>

Default for L<MooX::ConfigFromFile::Role/config_extensions>.

=item C<config_dirs>

Default for L<MooX::ConfigFromFile::Role/config_dirs>.
Same warning regarding modifying this attribute applies here:
Possible, but use with caution!

=item C<config_files>

Default for L<MooX::ConfigFromFile::Role/config_files>.

Reasonable when you want exactly one config file in development mode.
For production code it is highly recommended to override the builder.

=item C<config_singleton>

Flag adding a wrapper L<< around|Class::Method::Modifiers/around method(s) => sub { ... }; >>
the I<builder> of L<MooX::ConfigFromFile::Role/loaded_config> to ensure a
config is loaded only once per class. The I<per class> restriction results
from applicable modifiers per class (and singletons are per class).

=item C<config_identifier>

Default for L<MooX::File::ConfigDir/config_identifier>.

=back

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-moox-configfromfile at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-ConfigFromFile>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::ConfigFromFile

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-ConfigFromFile>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-ConfigFromFile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooX-ConfigFromFile>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-ConfigFromFile/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of MooX::ConfigFromFile
