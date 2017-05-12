#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Var;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Var - Application Shared variables.

=head1 SYNOPSIS
    
    # get  a reference to the the shared var object
    $var = $self->app->var;

    # set some variables
    $var->set('email', 'ahmed@mewsoft.com');
    $var->set('path', '/var/home/public_html/app');
    $var->set('lang', 'en-US');
    
    # auto setters
    $var->email('ahmed@mewsoft.com');
    $var->lang('en-US');

    # get some variables
    $mail = $var->get('email');
    $path = $var->get('path');
    $lang = $var->get('lang');
    
    # auto getters
    $mail = $var->email;
    $lang = $var->lang;

    # get variables or default values
    $value = $var->get('name', 'default');
    $path = $var->get('email', 'root@localhost');

    # set a list of variables 
    $var->set(%vars);
    $var->set(fname=>'Ahmed', lname=>'Elsheshtawy', email=>'ahmed@mewsoft.com');

    # get a list of variables 
    @values = $var->list(@vars);

    # get a list of variables names
    @names = $var->keys;
    
    # get a hash reference to the variables
    $vars = $var->vars;
    $vars->{path} = '/app/path';
    say $vars->{theme};

    # check if variables exist
    $found = $self->exists($name);

    # delete some vars
    $self->delete(@vars);

    # clear all vars
    $self->clear;

=head1 DESCRIPTION

Nile::Var - Application Shared variables.

=cut

use Nile::Base;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub AUTOLOAD {
my ($self) = shift;

    my ($class, $method) = our $AUTOLOAD =~ /^(.*)::(\w+)$/;

    if ($self->can($method)) {
        return $self->$method(@_);
    }

    if (@_) {
        $self->{vars}->{$method} = $_[0];
    }
    else {
        return $self->{vars}->{$method};
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 clear()
    
    # delete entire xml object data.
    $xml->clear();

Completely clears all loaded xml data from  memory. This does not apply to the file until file is
updated or saved.

=cut

sub clear {
    my ($self) = @_;
    $self->{vars} = +{};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 vars()
    
    # get all variables as a hash or a hash ref.
    %vars = $var->vars();
    $vars = $var->vars();

Returns all variables as a hash or a hash reference.

=cut

sub vars {
    my ($self) = @_;
    return wantarray? %{$self->{vars}} : $self->{vars};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 set()
    
    # set variables.
    $var->set("users_count", $count);
    $var->set(%vars);

    # automatic setter support
    $var->email('ahmed@mewsoft.com'); # same as $var->set('email', 'ahmed@mewsoft.com');

Set shared variables.

=cut

sub set {
    my ($self, %vars) = @_;
    map { $self->{vars}->{$_} = $vars{$_}; } keys %vars;
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 get()
    
    # get variables
    say $var->get("email");
    say $var->get("website", "default value");
        
    # automatic getter support
    say $var->email; # same as $var->get('email');

Returns shared variables.

=cut

sub get {
    my ($self, $name, $default) = @_;
    exists $self->{vars}->{$name}? $self->{vars}->{$name} : $default;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 list()
    
    # get a list of shared variables.
    @vars = $var->list(@names);

Returns a list of  shared variables.

=cut

sub list {
    my ($self, @n) = @_;
    @{$self->{vars}}{@n};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 keys()
    
    # returns all variables names.
    @names = $var->keys($);

Returns all shared variables names.

=cut

sub keys {
    my ($self) = @_;
    (keys %{$self->{vars}});
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 exists()
    
    # check if a variable exist or not.
    $found = $var->exists($name);

Check if a shared variable exist or not.

=cut

sub exists {
    my ($self, $name) = @_;
    exists $self->{vars}->{$name};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 delete()
    
    # delete shared variables.
    $var->delete(@names);

Delete a list of shared variables.

=cut

sub delete {
    my ($self, @n) = @_;
    delete $self->{vars}->{$_} for @n;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub DESTROY {
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
