# $Id: /mirror/Senna-Perl/lib/Senna/Symbol.pm 2738 2006-08-17T19:02:18.939501Z daisuke  $
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Senna::Symbol;
use strict;

sub create
{
    my $class = shift;
    my %args  = @_;

    $class->xs_create(@args{ qw(path key_size flags encoding) });
}

sub open
{
    my $class = shift;
    my %args  = @_;
    $class->xs_open(@args{qw(path)});
}

sub key
{
    my $self = shift;
    my %args = @_;
    $self->xs_key(@args{qw(id)});
}

sub next
{
    my $self = shift;
    my %args = @_;
    $self->xs_next(@args{qw(id)});
}

sub pocket_get
{
    my $self = shift;
    my %args = @_;
    $self->xs_pocket_get(@args{qw(id)});
}

sub pocket_set
{
    my $self = shift;
    my %args = @_;
    $self->xs_pocket_set(@args{qw(id)});
}

BEGIN
{
    no strict 'refs';
    no warnings 'redefine';

    foreach my $method qw(at get del common_prefix_search prefix_search suffix_search) {
        eval sprintf(<<'        EOSUB', $method, $method);
            sub %s 
            {
                my $self = shift;
                my %args = @_;
                $self->xs_%s(@args{qw(key)});
            }
        EOSUB
    }
}

1;

__END__

=head1 NAME

Senna::Symbol - Wrapper Around sen_sym

=head1 SYNOPSIS

   my $sym = Senna::Symbol->create(
       path => $path,
       key_size => $key_size,
       flags => $flags,
       encoding => $encoding
   );
   $sym = Senna::Symbol->open(path => $path);
   $sym->at(key => $key);
   $sym->get(key => $key);
   $sym->del(key => $key);
   $sym->size();

=head1 METHODS

=head2 create

=head2 at

=head2 close
=head2 common_prefix_search
=head2 del
=head2 get
=head2 key
=head2 next
=head2 open
=head2 pocket_get
=head2 pocket_set
=head2 prefix_search
=head2 size
=head2 suffix_search

=head1 AUTHOR

Copyright (C) 2005 - 2006 by Daisuke Maki <dmaki@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

Development funded by Brazil Ltd. E<lt>http://dev.razil.jp/project/senna/E<gt>

=cut