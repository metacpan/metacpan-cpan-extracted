package SQL::Load::Method;

use strict;
use warnings;
use SQL::Load::Util qw/
    parse
    name_list
/;

sub new {
    my ($class, $content) = @_;  
    
    my ($data, $hash, $keys, $list) = $class->_parse($content);
    
    my $self = {
        _data => $data,
        _hash => $hash,
        _keys => $keys,
        _list => $list,
        _next => 0
    };
    
    return bless $self, $class;
}

sub default {
    my $self = shift;
    
    return $self->{_hash}->{default} if exists $self->{_hash}->{default};
    return $self->{_list}->[0]       if exists $self->{_list}->[0];
    
    return;
}

sub name {
    my ($self, $name) = @_;
    
    my $real = exists $self->{_keys}->{$name} ? $self->{_keys}->{$name} : $name;   
                      
    return $self->{_hash}->{$real} if exists $self->{_hash}->{$real};
    
    return;
}

sub next {
    my $self = shift;
    
    if (defined $self->{_next}) {
        my $next = $self->{_next}++;
        
        return $self->{_list}->[$next] if exists $self->{_list}->[$next];
        
        $self->{_next} = undef;
    }
    
    return;
}

sub at {
    my ($self, $index) = @_;
    
    return $self->{_list}->[$index - 1] if exists $self->{_list}->[$index - 1];
    
    return;
}

sub first {
    my $self = shift;
    
    return $self->{_list}->[0];
}

sub last {
    my $self = shift;
    
    return $self->{_list}->[-1];
}

sub replace {
    my $self = shift;
    
    my %replace = @_;
    
    for my $name (keys %replace) {
        my $value = $replace{$name};
        
        # replace in hash
        for my $key (keys %{$self->{_hash}}) {
            $self->{_hash}->{$key} =~ s/${name}/${value}/g;
        }
        
        # replace in list
        for (my $i = 0; $i < scalar(@{$self->{_list}}); $i++) {
            $self->{_list}->[$i] =~ s/${name}/${value}/g;
        }
    }
    
    return $self;
}

sub reset {
    my $self = shift;
    
    my @data = @{$self->{_data}};
    
    # reset hash
    my %hash = @data;
    $self->{_hash} = \%hash;
    
    # reset list
    my @list;
    for (my $i = 0; $i < scalar(@data); $i += 2) {        
        push(@list, $data[$i + 1]);
    }  
    $self->{_list} = \@list; 
    
    # reset next
    $self->{_next} = 0;
    
    return $self;
}

sub _parse {
    my ($self, $content) = @_;
    
    my @data = parse($content);
    my %hash = @data;
    my %keys;
    my @list;
    
    for (my $i = 0; $i < scalar(@data); $i += 2) {
        my $name = $data[$i];
        my @name_list = name_list($name);
        
        for (@name_list) {
            $keys{$_} = $name;
        }
        
        push(@list, $data[$i + 1]);
    }
    
    return (\@data, \%hash, \%keys, \@list);    
}

1;

__END__

=encoding utf8
 
=head1 NAME
 
SQL::Load::Method

=head1 SYNOPSIS

    my $sql = q{
        -- [find]
        SELECT * FROM users WHERE id = ?;
        
        -- [find-by-email]
        SELECT * FROM users WHERE email = ?;        
    };

    my $method = SQL::Load::Method->new($sql);
    
    # SELECT * FROM users WHERE id = ?;
    print $method->name('find');
    
    # SELECT * FROM users WHERE email = ?;
    print $method->name('find-by-email');
    
=head1 DESCRIPTION

L<SQL::Load::Method> contains useful methods to L<SQL::Load>, 
method load from L<SQL::Load> returns a reference.

=head1 METHODS

=head2 new

    my $method = SQL::Load::Method->new($sql);

construct a new L<SQL::Load::Method>.

=head2 default

    $method->default;
    
returns the first SQL or SQL named as default.

=head2 name

    # -- # name
    # -- [name]
    # -- (name)

    $method->name('name');
    
returns SQL by name.
  
=head2 next

    while (my $sql = $method->next) {
        print $sql;
    }
    
returns the next SQL like an iterator.

=head2 at

    $method->at(1);
    
returns the SQL by position in the list, starting with 1.


=head2 first

    $method->first;
    
returns first the SQL.

=head2 last

    $method->last;
    
returns last the SQL.

=head2 replace

    $method->replace('value', 'new_value')->name('find');
    $method->replace(value => 'new_value')->first;
    $method->replace('value1', 'new_value1', 'value2', 'new_value2')->at(1);
    $method->replace(value1 => 'new_value1', value2 => 'new_value2')->last;
    
replaces values and returns the reference itself.

=head2 reset

    $method->reset;
    
reset to SQL original and returns the reference itself.

=head1 SEE ALSO
 
L<SQL::Load>.
 
=head1 AUTHOR
 
Lucas Tiago de Moraes, C<lucastiagodemoraes@gmail.com>.
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2022 by Lucas Tiago de Moraes.
 
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
 
=cut


    
    
