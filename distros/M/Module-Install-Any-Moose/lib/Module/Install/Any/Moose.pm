
package Module::Install::Any::Moose;
use strict;
use Module::Install::Base;

use vars qw($VERSION @ISA $ISCORE);
BEGIN {
    $VERSION = '0.00003';
    $ISCORE  = 0;
    @ISA     = qw(Module::Install::Base);
}

sub requires_any_moose {
    my $self = shift;
    my ($module, %args);

    if (@_ % 2 == 0) {
        %args = @_;
    } else {
        ($module, %args) = @_;
    }

    my $prefer = ($args{prefer} ||= 'Mouse');

    my $requires = $self->requires;
    if (! grep { $_->[0] eq 'Any::Moose' } @$requires ) {
        print "Adding Any::Moose to prerequisites...\n";
        $self->requires('Any::Moose', 0.04);
    }

    $self->_any_moose_setup($prefer, $module, %args);
    $self->_any_moose_setup(
        ($prefer eq 'Mouse' ? 'Moose' : 'Mouse'), $module, %args );
}

sub _any_moose_setup {
    my ($self, $prefix, $frag, %args) = @_;

    my $module  = $frag ? $prefix . $frag : $prefix;

    my $prefer  = $args{ prefer };
    my $version = $args{ lc $prefix };
    if ($prefer eq $prefix) {
        $self->requires($module, $version);
    } else {
        print "[Any::Moose support for $module]\n",
              "- $module ... ";

        # ripped out of ExtUtils::MakeMaker
        my $file = "$module.pm";
        $file =~ s{::}{/}g;
        eval { require $file };

        my $pr_version = $module->VERSION || 0;
        $pr_version =~ s/(\d+)\.(\d+)_(\d+)/$1.$2$3/;

        if ($@) {
            print "missing\n";
            my $y_n = ExtUtils::MakeMaker::prompt("  Add $module to the prerequisites?", 'n');
            if ($y_n =~ /^y(?:es)?$/i) {
                $self->requires($module, $version);
            } else {
                $self->recommends($module, $version);
            }
        } else {
            print "loaded ($pr_version)\n";
            $self->recommends($module, $version);
        }
    }
}

1;

__END__

=head1 NAME

Module::Install::Any::Moose - Any::Moose Support For Module::Install

=head1 SYNOPSIS 

    use inc::Module::Install;

    # your usual stuff...

    # This will ask the user if MouseX::AttributeHelpers should be installed
    requires_any_moose 'X::AttributeHelpers'; 

    WriteAll;

=head1 METHODS

=head2 requires_any_moose(%opts)

Speicifies Mouse/Moose as requirements. See the next entry for details on %opts

=head2 requires_any_moose($module, %opts)

Specifies Mouse/Moose extensions as requirements.

$module should be a module name fragment, like '::Util::TypeConstraints' or
'X::AttributeHelpers'.

%opts may contain the following values:

=over 4

=item prefer $prefix

Specify 'Moose' or 'Mouse'. This will tell Module::Install::Any::Moose to check for $prefix's version as the requirement. The other one would be an optional module.

The default is Mouse.

=item moose $version

Specify the Moose alternative's minimum version.

=item mouse $version

Specify the Mouse alternative's minimum version.

=back

As an example, the following would require MooseX::AttributeHelpers 0.13, and MouseX::AttributeHelpers as an optional dependency:

    requires_any_moose 'X::AttributeHelpers' => (
        prefer => 'Moose',
        moose => '0.13',
        mouse => '0.01'
    );

=head1 AUTHOR

Daisuke Maki C<< daisuke@endeworks.jp >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
