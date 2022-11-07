package SQL::Load::Util;

use strict;
use warnings;
use String::CamelCase qw/
    camelize 
    decamelize
/;
use base qw/Exporter/;
 
our @EXPORT_OK = qw/
    name_list
    parse
    remove_extension
    trim
/;

sub name_list {
    my $name = shift;
    
    my @list;
    
    $name = remove_extension($name);
    
    $name =~ s/-/_/xg;
    push @list, camelize $name;
    
    $name = decamelize $name;
    push @list, $name;
    
    $name =~ s/_/-/xg;
    push @list, $name;
    
    return wantarray ? @list : \@list;    
}

sub parse {
    my $content = shift;
    
    # get all sql by name
    my (@data) = $content =~ /--\s*(?:#|\[|\()\s*([\w-]+)\s*(?:|]|\))\n([^;]+;)/g;
    
    # get all sql without name
    unless (@data) {
        my (@list) = $content =~ /([^;]+;)/g;
        
        my $num = 1;
        for my $sql (@list) {
            push(@data, $num++);
            push(@data, trim($sql));
        }
        
        # if got one or nothing, set content as default
        unless (@data) {            
            push(@data, 'default');
            push(@data, trim($content));
        }        
    }
    
    return wantarray ? @data : \@data;    
}

sub remove_extension {
    my $value = shift;
    
    $value =~ s/\.sql$//i if $value;
    
    return $value;
}

sub trim {
    my $value = shift;
    
    $value =~ s/^\s+|\s+$//g;
    
    return $value;
}

1;

__END__

=encoding utf8
 
=head1 NAME
 
SQL::Load::Util

=head1 SYNOPSIS

    use SQL::Load::Util qw/
        name_list 
        parse
        remove_extension
        trim
    /;
    
    my $name_list = name_list('foo');
    
    my %parse = (parse(SQL));
    
    my $remove_extension = remove_extension('file.sql');
    
    my $trim = trim('   baz   ');

=head1 DESCRIPTION

L<SQL::Load::Util> contains useful methods to L<SQL::Load>.

=head1 METHODS

=head2 name_list

    # ['FindAll', 'find_all', 'find-all']
    my $name_list = name_list('find_all');

returns an array or arrayref with three formats: CamelCase, snake_case and kebab-case.

=head2 parse

    my $data = q{
        -- [find]
        SELECT * FROM foo WHERE id = ?;
        
        -- [find-all]
        SELECT * FROM foo ORDER BY id DESC;
    };
    
    # [
    #   'find',
    #   'SELECT * FROM foo WHERE id = ?;',
    #   'find-all',
    #   'SELECT * FROM foo ORDER BY id DESC;'
    # ]
    my $parse = parse($data);
    
returns an array or arrayref with name in the even position and SQL in the odd position.

=head2 remove_extension

    # users
    my $remove_extension = remove_extension('users.sql')

remove the extension .sql 

=head2 trim

    # foo
    my $trim = trim('  foo   ');

remove spaces at the begin and end

=head1 SEE ALSO
 
L<SQL::Load>.
 
=head1 AUTHOR
 
Lucas Tiago de Moraes, C<lucastiagodemoraes@gmail.com>.
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2022 by Lucas Tiago de Moraes.
 
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
 
=cut
