#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Base;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Base - Base class for the Nile framework.

=head1 SYNOPSIS
        
    package Nile::MyModule;

    use Nile::Base;

    1;

=head1 DESCRIPTION

Nile::Base - Base class for the Nile framework.

=cut

use utf8;
use Moose;
use MooseX::Declare;
use MooseX::MethodAttributes;
use Import::Into;
use Module::Runtime qw(use_module);
#use true; # both load and import it
#use Nile::Declare;

use Nile::Say;
#use Nile::Declare ('method' => 'method', 'function' => 'function', 'invocant'=>'$this', 'inject'=>'my ($me) = $this->me;');

no warnings 'redefine';
no strict 'refs';
# disable the auto immutable feature of Moosex::Declare, or use class Nile::Home is mutable {...}
*{"MooseX::Declare::Syntax::Keyword::Class" . '::' . "auto_make_immutable"} = sub { 0 };
#around auto_make_immutable => sub { 0 };

our @EXPORT_MODULES = (
        #strict => [],
        #warnings => [],
        Moose => [],
        utf8 => [],
        #true => [],
        'Nile::Say' => [],
        #'Nile::Declare' => ['method' => 'method', 'function' => 'function', 'invocant'=>'$self', 'inject'=>'my ($me) = $self->me;'],
        'MooseX::Declare' => [],
        #'Nile::Declare' => [],
        'MooseX::MethodAttributes' => [],
        #'MooseX::ClassAttribute' => [],
        #'Module::Load' => [()], # will emit error for methods load redefined
    );

sub import {
    my ($class, %args) = @_;
    my $caller = caller;
    my @modules = @EXPORT_MODULES;
    while (@modules) {
        my $module = shift @modules;
        my $imports = ref $modules[0] eq 'ARRAY' ? shift @modules : [];
        use_module($module)->import::into($caller, @{$imports});
    }
}

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
