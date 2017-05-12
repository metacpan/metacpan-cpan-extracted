package Teng::Plugin::RowObjectCreationSwitcher;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.03";

use Scope::Guard;
use Carp qw();

our @EXPORT = qw(temporary_suppress_row_objects_guard);

sub temporary_suppress_row_objects_guard {
    my ($self, $new_status) = @_;

    if( @_ < 2 ) { #missing $new_status
        Carp::croak('error: missing argument');
    }

    my $current_status = $self->suppress_row_objects(); #preserve current(for guard object)
    $self->suppress_row_objects($new_status);

    return Scope::Guard->new(sub { 
        $self->suppress_row_objects($current_status);
    });
}



1;
__END__

=encoding utf-8

=head1 NAME

Teng::Plugin::RowObjectCreationSwitcher - Teng plugin which enables/disables suppress_row_objects with guard object

=head1 SYNOPSIS

    use MyProj::DB;
    use parent qw(Teng);
    __PACKAGE__->load_plugin('RowObjectCreationSwitcher');

    package main;
    my $db = MyProj::DB->new(dbh => $dbh);
    {
        my $guard = $db->temporary_suppress_row_objects_guard(1); # row object creation is suppressed
        {
            my $guard2 = $db->temporary_suppress_row_objects_guard(1); # row object is created. (isn't suppressed)
            ... # do something
        }
        # dismiss $guard2 (row object creation is suppressed)
        ... # do something
    }
    # dismiss $guard (row object creation is unsuppressed)

=head1 DESCRIPTION

Teng::Plugin::RowObjectCreationSwitcher is plugin for L<Teng> which provides switcher to enable/disable to generate row object.
This switcher returns guard object and if guard is dismissed, status is back to previous.

=head1 METHODS

=head2 $guard = $self->temporary_suppress_row_objects_guard($bool_suppress_row_objects)

set suppress_row_objects and return guard object.  When guard is dismissed, status is back to previous.

=head1 LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi@cpan.orgE<gt>

=cut

