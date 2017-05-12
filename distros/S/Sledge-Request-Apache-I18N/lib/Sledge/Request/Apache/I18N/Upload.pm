package Sledge::Request::Apache::I18N::Upload;
use strict;

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(upload));

use vars qw($AUTOLOAD);

sub new {
    my $class = shift;
    my $r   = shift;
    my @upload = $r->req->upload(@_);
    my @list;
    for (@upload) {
        next unless $_->size;
        my $self = bless {upload => $_}, $class;
        push @list, $self;
    }
    return wantarray ? @list : shift @list;
}

sub DESTROY { }

sub AUTOLOAD {
    my $self = shift;
    (my $meth = $AUTOLOAD) =~ s/.*:://;
    $self->upload->$meth(@_);
}


1;
