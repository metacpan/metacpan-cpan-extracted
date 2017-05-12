package SQL::Object::Interp;
use strict;
use warnings;
use utf8;
use base 'SQL::Object';
use Exporter qw/import/;

our @EXPORT_OK = qw/isql_obj/;

our $VERSION = '0.04';

sub isql_obj {
    require SQL::Interp;
    my ($sql, @args) = SQL::Interp::sql_interp(@_);
    my $bind = [@args];
    SQL::Object::Interp->new(sql => $sql, bind => $bind);
}

sub _compose {
    my ($self, $op, $sql, @bind) = @_;

    $self->{sql} = $self->{sql} . " $op " . $sql;
    $self->{bind} = [@{$self->{bind}}, @bind];
    $self;
}

sub _no_compose {
    my ($self, $sql, @bind) = @_;
    $self->{sql} = $sql;
    $self->{bind} = [@bind];
    $self;
}

sub and {
    my ($self, @args) = @_;
    if(defined $self->{sql} && $self->{sql} ne ''){
        $self->_compose('AND', SQL::Interp::sql_interp(@args));
    }else{
        $self->_no_compose(SQL::Interp::sql_interp(@args));
    }
}

sub or {
    my ($self, @args) = @_;
    if(defined $self->{sql} && $self->{sql} ne ''){
        $self->add_parens->_compose('OR', SQL::Interp::sql_interp(@args));
    }else{
        $self->_no_compose(SQL::Interp::sql_interp(@args));
    }
}

sub compose_and {
    my ($self, $other) = @_;
    if(defined $self->{sql} && $self->{sql} ne ''){
        $self->_compose('AND', $other->{sql}, @{$other->{bind}});
    }else{
        $self->_no_compose($other->{sql}, @{$other->{bind}});
    }
}

sub compose_or  {
    my ($self, $other) = @_;
    if(defined $self->{sql} && $self->{sql} ne ''){
        $self->add_parens->_compose('OR', $other->add_parens->{sql}, @{$other->{bind}});
    }else{
        $self->_no_compose($other->add_parens->{sql}, @{$other->{bind}});
    }
}


1;
__END__

=head1 NAME

SQL::Object::Interp - Yet another SQL condition builder with SQL::Interp

=head1 SYNOPSIS

    use SQL::Object::Interp qw/isql_obj/;
    
    my $sql = isql_obj('foo.id =', \1, 'AND', 'bar.name =', \'nekokak');
    $sql->as_sql; # 'foo.id = ? AND bar.name = ?'
    $sql->bind; # qw/1 nekokak/
    
    my $class = 5;
    $sql->and('baz.class =', \$class);
    $sql->as_sql; # 'foo.id = ? AND bar.name = ? AND baz.class = ?'
    $sql->bind; # qw/1 nekokak 5/
    
    my $bar_age = 33;
    $sql->or('bar.age =', \$bar_age);
    $sql->as_sql; # '(foo.id = ? AND bar.name = ? AND baz.class = ?) OR bar.age = ?'
    $sql->bind; # qw/1 nekokak 5 33/
    
    my $cond = isql_obj('foo.id =', \2);
    $sql = $sql | $cond;
    $sql->as_sql; # '((foo.id = ? AND bar.name = ? AND baz.class = ?) OR bar.age = ?) OR (foo.id = ?)'
    $sql->bind; # qw/1 nekokak 5 33 2/
    
    $cond = isql_obj('bar.name =',\'tokuhirom');
    $sql = $sql & $cond;
    $sql->as_sql; # '((foo.id = ? AND bar.name = ? AND baz.class = ?) OR bar.age = ?) OR (foo.id = ?) AND bar.name = ?'
    $sql->bind; # qw/1 nekokak 5 33 2 tokuhirom/
    
    $sql = isql_obj('SELECT * FROM user WHERE ') + $sql;
    
    $sql->as_sql; # 'SELECT * FROM user WHERE ((foo.id = ? AND bar.name = ? AND baz.class = ?) OR bar.age = ?) OR (foo.id = ?) AND bar.name = ?'
    
    my $sql_no = isql_obj;
    $sql_no->and('foo.id =', \2);
    $sql_no->as_sql; # 'foo.id = ?'
    $sql_no->bind; # 2

=head1 DESCRIPTION

SQL::Object::Interp is an extension of raw level SQL maker "SQL::Object".

SQL::Object::sql_obj is incompatible with SQL::Interp::sql_interp which returns ($stmt, @binds).

SQL::Object::Interp::isql_obj is a substitute of sql_obj which is compatible with SQL::Interp (like DBIx::Simple::iquery).

=head1 METHODS

SQL::Object::Interp inherits SQL::Object.

=head2 my $sql = isql_obj(args for sql_interp)

create SQL::Object::Interp's instance.

Uses SQL::Interp to generate $stmt, $bind(s).
See SQL::Interp's documentation for usage information.

=head2 my $sql = SQL::Object->new(sql => $sql, bind => \@bind); # SQL::Object's method

create SQL::Object::Interp's instance

=head2 $sql = $sql->and(args for sql_interp)

compose sql. operation 'AND'.

=head2 $sql = $sql->or(args for sql_interp)

compose sql. operation 'OR'.

=head2 $sql = $sql->compose_and($sql)

compose sql object. operation 'AND'.

=head2 $sql = $sql->compose_or($sql)

compose sql object. operation 'OR'.

=head2 $sql->add_parens() # SQL::Object's method

bracket off current SQL.

=head2 $sql->as_sql() # SQL::Object's method

get sql statement.

=head2 $sql->bind() # SQL::Object's method

get sql bind variables.

=head1 AUTHOR

Narazaka (http://narazaka.net/)

=head1 SEE ALSO

L<SQL::Object>

L<SQL::Interp>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
