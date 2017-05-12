#
# This file is part of MooseX-Role-AttributeOverride
#
# This software is copyright (c) 2011 by Edward J. Allen III.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package MooseX::Role::AttributeOverride;
BEGIN {
  $MooseX::Role::AttributeOverride::VERSION = '0.0.9';
}
BEGIN {
  $MooseX::Role::AttributeOverride::AUTHORITY = 'cpan:EALLENIII';
}
# ABSTRACT: Allow roles to modify attributes
use 5.008;
use utf8;
use Moose 1.9900 ();
use Moose::Role 1.9900;
use Moose::Exporter;

use MooseX::Role::AttributeOverride::Meta::Trait::Role;
use MooseX::Role::AttributeOverride::Meta::Trait::Role::ApplicationToClass;
use MooseX::Role::AttributeOverride::Meta::Trait::Role::ApplicationToRole;
use MooseX::Role::AttributeOverride::Meta::Trait::Role::Composite;


BEGIN {

    sub has_plus {
        my ($meta, $name, %options) = @_;
        if ($name =~ /\A \+/xms) {
            Moose->throw_error('Do not use a plus prefix with the has_plus sugar');
        }
        if ($meta->can('add_attribute_modifier')) {
            $meta->add_attribute_modifier([ $name => \%options ]);
        }
        else {
            require Moose;
            Moose->throw_error('Attempt to call has_plus on an invalid object');
        }
        return;
    }

    Moose::Exporter->setup_import_methods(
    with_meta => ['has_plus'],
    role_metaroles => {
            role =>
                ['MooseX::Role::AttributeOverride::Meta::Trait::Role'],
            application_to_class =>
                ['MooseX::Role::AttributeOverride::Meta::Trait::Role::ApplicationToClass'],
            application_to_role =>
                ['MooseX::Role::AttributeOverride::Meta::Trait::Role::ApplicationToRole'],
        },
        also => 'Moose::Role',
    );
}



1; # Magic true value required at end of module


=pod

=for :stopwords Edward Allen <ealleniii_at_cpan_dot_org> J. III cpan testmatrix url
annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata
placeholders MooseX MyApp

=encoding utf-8

=head1 NAME

MooseX::Role::AttributeOverride - Allow roles to modify attributes

=head1 VERSION

  This document describes v0.0.9 of MooseX::Role::AttributeOverride - released June 29, 2011 as part of MooseX-Role-AttributeOverride.

=head1 SYNOPSIS

    {
        package MyApp::Role;
        use Moose::Role;
        use MooseX::Role::AttributeOverride;

        has_plus 'fun' => ( default => 'yep', );

        has_plus 'alive' => (
            default => 'yep',
            override_ignore_missing => 1,
        );
    }
    {
        package MyApp::Trait;
        use Moose::Role;
        use MooseX::Role::AttributeOverride;

        has_plus default => (
            default => sub {
                my $attr = shift;
                return sub { $attr->name }
            }
        );
    }
    {
        package MyApp;
        use Moose 1.9900;

        has nolife => (
            is     => 'rw',
            isa    => 'Str',
            traits => ['MyApp::Trait'],
        );

        has 'fun' => (
            is  => 'rw',
            isa => 'Str'
        );

        with qw(MyApp::Role);
    }
    {
        package main;
        use feature 'say';

        my $test = MyApp->new();

        say "I have " . $test->nolife;
        # Says I have nolife
        say "Are you having fun? " . $test->fun;
        # Says Are you having fun? yep

    }

=head1 DESCRIPTION

Moose doesn't allow roles to override attributes using the has '+attr' method.
There are several good reasons for that. Basically, "that's not what a role
is for."  A role is a set of requirements with defaults. A class should
always be able to override a role.

But sometimes you want a role to B<add> features to a class. This is why Moose
has method modifiers. This extension adds attribute modifiers.

=head1 INTERFACE 

=over

=item has_plus

This has exactly the same syntax as the Moose L<has|Moose/has> command, except
you should not use a plus to indicate you are overriding an attribute. 

=item has_plus options

=over

=item override_ignore_missing

Setting this to a true value will allow your role to have modifications to attributes 
that may not exist in the class it is applied to. The default is to die in these
cases.

For example:

    package MyApp::Role;
    use Moose::Role;
    use MooseX::Role::AttributeOverride;

    has_plus 'alive' => (
        default => 'yep',
        override_ignore_missing => 1,
    );

    package MyApp;
    use Moose;

    with qw(MyApp::Role);
    # I'm not dead yet.

The above would not die, even though the MyApp package has no attribute named
'fun.'

=back

=back

=head1 IMPORTANT NOTE

Always apply a role that uses this module B<after> defining attributes.

=head1 META USAGE

This role can be used in traits.  For example, the following works:

    {
        package MyApp::Trait;
        use Moose::Role;
        use MooseX::Role::AttributeOverride;

        has_plus default => (
            default => sub {
                my $attr = shift;
                return sub { $attr->name }
            }
        );
    }
    {
        package MyApp;
        use Moose 1.9900;

        has nolife => (
            is     => 'rw',
            isa    => 'Str',
            traits => ['MyApp::Trait'],
        );

        with qw(MyApp::Role);
    }
    {
        package main;
        use feature 'say';

        my $test = MyApp->new();

        say "I have " . $test->nolife;
        # Says I have nolife
    }

=head1 DIAGNOSTICS

=over

=item Can't find attribute $attr required by $role

You will see this error if your role has an attribute modification for an
attribute that is not in the class. You can squash this by setting the
'override_ignore_missing' option in your 'has_plus' command.

=item Attempt to call has_plus on an invalid object

You really should never see this. Please file a bug report if you do. A test
case would be nice as well.

=item Illegal inherited options 

Moose will throw this error if you try to change an accessor option. See 
L<the Moose manual|Moose::Manual::Attributes/"ATTRIBUTE INHERITANCE"> for more
details.

=item Do not use a plus prefix with the has_plus sugar

There is no need for a plus sign on your attribute:

    # Good
    has 'children', trait => ['good']

    # Bad. Will die.
    has '+children', trait => ['naughty']

=back

=head1 DEPENDENCIES

Moose 1.9900 or newer. Older versions may be supported in a future version of
this module.

=head1 INCOMPATIBILITIES

I am sure that there are some MooseX modules that will not work with this.
Please let me know, and I will at least document them.

=head1 BUGS AND LIMITATIONS

This is not the intended use of roles. As a result, take into account the
following:

=over

=item *

Order matters! If two roles modify the same attribute in the same way,
the second one applied will be the one that is used. This behavior, however,
relies on Moose keeping track of order, which it generally does a good job of,
but no guarantees.

=item *

Currently, the value of the attribute is clobbered when the role is applied.
This may change in the future.

=item *

This works the same as '+has'. This means that you can't override accessor
methods. This is a very sensible Moose limitation.

=item *

After having an issue with Moose, clone_and_inherit_options, and traits that
use _process_options, I reimplemented clone_and_inherit_optiosn in a way that
fixes it.  Sort of.  A side effect of this is that has_plus will not allow you
to override the lazy option, without a default or builder option.

=item *

If you try adding this role before adding the attributes, it won't work.

=back

I am relatively new to Moose. I had an itch, and wrote this Module to scratch
it. Please let me know how to make this module better.

For bugs, test cases are great! 

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Moose|Moose>

=item *

L<Moose::Manual::Attributes|Moose::Manual::Attributes>

=back

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/MooseX-Role-AttributeOverride>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=MooseX::Role::AttributeOverride>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/MooseX-Role-AttributeOverride>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/M/MooseX-Role-AttributeOverride>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual way to determine what Perls/platforms PASSed for a distribution.

L<http://matrix.cpantesters.org/?dist=MooseX-Role-AttributeOverride>

=back

=head2 Email

You can email the author of this module at C<EALLENIII at cpan.org> asking for help with any problems you have.

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-moosex-role-attributeoverride at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Role-AttributeOverride>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/riemann42/MooseX-Role-AttributeOverride>

  git clone git://github.com/riemann42/MooseX-Role-AttributeOverride.git

=head1 AUTHOR

Edward Allen <ealleniii_at_cpan_dot_org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edward J. Allen III.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

