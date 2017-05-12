package MySQL::TableInfo;

use strict;
use Carp;

our $VERSION = '1.01';

####
# takes care of plural forms of methods and 'get_' prefix
####################
#sub AUTOLOAD {  }





####
# initializes the object with table information
####################
sub _init {
    my ($self, $table) = @_;

    $self->{"_data"} = $self->{"_dbh"}->selectall_arrayref(qq/SHOW COLUMNS FROM $table/);

    unless ( $self->{"_data"} ) {
        croak "Table '$table' doesn't seem to exist";
    }

    $self->{"table_info"} = { };

    foreach my $row ( @{ $self->{"_data"} } ) {
        $self->{"table_info"}->{ $row->[0] } = $row;
    }
}


####
# constructor method
####################
sub new {
    my ($class, $dbh, $table) = @_;

    unless ($dbh && $table) {
        croak <<'END_OF_USAGE';
new() was called with insufficient arguments

Usage:
    MySQL::TableInfo->new($dbh, $table)
END_OF_USAGE
    }

    $class = ref($class) || $class;

    my $self = {
            _dbh        =>  $dbh,
            _data       =>  [],
            table_info  =>  {},
    };

    bless $self => $class;

    $self->_init($table);

    return $self;
}





####
# desctructor method
####################
sub DESTROY { }






####
# gets the column name or names
####################
sub column {
    my ($self, $column) = @_;

    if ($column) {
        return @{$self->{table_info}{$column}};
    }

    return keys %{$self->{table_info}};
}



####
# gets the size of the column
####################
sub size {
    my ($self, $col) = @_;

    if ( $self->{table_info}{$col}[1] =~ m/\((\d+)\)/ ) {
        return $1;
    }

    return undef;
}





####
# gets the type of the column
####################
sub type {
    my ($self, $col) = @_;

    if ($self->{table_info}{$col}[1] =~ m/(\w+)/) {
        return $1;
    }

    return undef;
}



####
# gets the default values of the column
####################
sub default {
    my ($self, $col) = @_;

    return $self->{table_info}->{$col}[4];

}



####
# gets the extra information about the column
####################
sub extra {
    my ($self, $col) = @_;

    if ($col) {
        return $self->{table_info}{$col}[5];
    }

    return undef;
}




####
# determines if the column can hold NULL
####################
sub is_null {
    my ($self, $col) = @_;

    if ( $self->{table_info}{$col}[2] =~ /^yes$/i ) {
        return 1;
    }

    return undef;
}



####
# gets the values of the set column
####################
sub set {
    my ($self, $col) = @_;
    my @set;

    if ( $self->{table_info}{$col}[1] =~ m/\((.+?)\)/ ) {

        @set = split(",", $1);
        map {s/^'(.+)'$/$1/} @set;

        return @set;
    }

}




####
# gest the values of the enumeration column; uses set()
####################
sub enum {
    my ($self, $col) = @_;

    return $self->set($col);
}




####
# initializes default vlues into a CGI object
####################
sub load_default {
    my ($self, $CGI) = @_;

    unless ($CGI) {
        croak "load_default() needs a CGI object to be passed as an argument";
    }

    foreach my $col ( $self->column ) {
        $CGI->param(-name=>$col, -value=>$self->default($col) );
    }

}



####
# checks if the CGI parameters' values are valid
# according to their corresponding mysql-table-columns
##---------- Note:--
#   Still not working properly. I can feel the need for couple of private methods
#   to make this validate() thing possible
####################
sub validate {
    my ($self, $CGI)  = @_;

    unless ($CGI) {
        croak "validate() needs a CGI object to be passed as an argument";
    }

    my %error;

    foreach my $col ($self->column) {

        next unless $CGI->param($col);

        if ( $self->type($col) =~ m/^int$/i) {
            $error{$col}.= " Not an integer," unless $CGI->param($col) =~ m/^\d+$/;
        }

        if ( $self->size($col) && ( length($CGI->param($col) ) > $self->size($col) ) ) {
            $error{$col}.= " Longer than expected,";
        }

        if ( $self->type($col) =~ m/^enum$/i) {
            my $exists;
            foreach my $enum ( $self->enum($col) ) {
                if ($CGI->param($col) =~ m/$enum/i) {
                    $exists = 1;
                    last;
                }
            }

            $error{$col}.= $CGI->param($col). " is not a supported option" unless $exists;
        }

    }

    return %error;
}

#---
# checks if the parameter is a valid enum element
##--Note:-----------
# currently not implemented
#-------------------
sub _valid_enum {
    my ($self, $param) = @_;

    return 1;
}

#---
# checks if the parameter is a valid set element
##---Note:----------
# currently not implemented
#-------------------
sub _valid_set {
    my ($self, $param) = @_;

    return 1;
}


#---
# dumps the object into __PACKAGE__.dmp file
# for debugging purposes
#-------------------
sub _dump {
    my $self = shift;

    require Data::Dumper;

    open DATA, ">".__PACKAGE__.".dmp" or die "Couldn't dump: $!\n";
    print DATA Dumper($self);
    close DATA;

}



1;

__END__
# Below is stub documentation for the library

=head1 NAME

MySQL::TableInfo - Perl extension for getting access into mysql's column information.

=head1 RATIONALE

The idea was taken from Paul DuBois' "MySQL and Perl for the Web" book. I searched the CPAN
but failed to find any module that does the similar task and thought of putting one
together and upload to CPAN. And  here it is.

=head1 NOTE

The library has been tested on MySQL version 3.23.40

=head1 SYNOPSIS

    use CGI;
    use DBI;
    use MySQL::TableInfo;

    my $CGI = new CGI:
    my $dbh = DBI->connect(....);
    my $table = new MySQL::TableInfo($dbh, "bio");

    print $CGI->header,
        $CGI->start_html("MySQL::TableInfo"),
        $CGI->start_form,
        $CGI->div("Do you have beard?"),
        $CGI->popup_menu(-name=>'has_beard',
                         -values=>[$table->enum('has_beard')],
                         -default=>$table->default('has_beard')),
    $CGI->end_form,
    $CGI->end_html;


=head1 DESCRIPTION

MySQL::TableInfo is a handy class for getting easy access to MySQL tables' descriptions
which is available via

    DESCRIBE table_name, SHOW COLUMNS FROM table_name

queries. It's also handy for constructing form based CGI applications to control HTML forms'
attributes such as C<VALUE>, C<SIZE>, C<MAXLENGTH>, C<TYPE> and so forth.
For example, if you have a ENUM('Yes', 'No') column in your mysql table, then you normally
would present it either as a group of radio buttons, or as a <SELECT> menu. If you modify
the column, and add one more option, ENUM('Yes', 'No', 'N/A'), then you will have to
re-write your html code accordingly. By using MySQL::TableInfo, you can avoide this double
troubles. Consider the following code:

    use CGI;
    use DBI;
    use MySQL::TableInfo;

    my $CGI = new CGI:
    my $dbh = DBI->connect(....);
    my $table = new MySQL::TableInfo($dbh, "bio");

    print $CGI->header, $CGI->start_html("MySQL::TableInfo");

    print $CGI->start_form,
        $CGI->div("Do you wear beard?"),
        $CGI->checkbox_group( -name=>'has_beard',
                              -values=>[$table->set('has_beard')],
                              -default=>$table->default('has_beard')),
    $CGI->end_form;

    print $CGI->end_html;

As you see, modifying 'has_beard' column, which is an enumeration column, whould
reflect in your CGI too.

=head1 METHODS

=over 4

=item C<new($dbh, 'table_name')>

constructor method. The two reguired arguments are database handle ($dbh) returned from DBI->connect(), and the name of the mysql table to work with. Since you create the $dbh with the database name, it is not required to pass the database name to C<new()>. If you really want to, you can prescribe the database name in front of the "table_name" delimited with a period. Example:

    my $table = new MySQL::TableInfo($dbh, "database.table_name");

=item C<column([$column_name])>

if invoked with a column name returns an array consisting of all the column's attributes. If the argument is missing returns an array consisting table's all the columns. For example, the following code prints all the column names:

    foreach my $col ($table->column) {
        print "$col\n";
    }

You can also print all the column names together with their attributes by slightly modifying the above code:

    foreach my $col ($table->column) {
        print "$col => ", join (" : ", $table->column($col) ), "\n";
    }

Of course the above example is pretty awkward if we want to gain access to each attribute of the columns (like size, default values, sets, enumeations and etc) seperately. But the cure is comming below, read on

=item C<size($column_name)>

returns the size of the $column_name. If the column doesn't have any size attribute (such as TEXT?) it returns I<undef>

=item C<type($column_name)>

returns the type of the column. The possible values returned from this method include: I<varchar>, I<char>, I<text>, I<int>, I<set>, I<enum> and so forth.

=item C<default($column_name)>

returns default values for the $column_name

=item C<is_null($column_name)>

returns true if the $column_name can hold NULL value, false otherwise.

=item C<set($column_name)>

returns an array consisting of all the possible options of the SET column type.

=item C<enum($column_name)>

the same as set(), but implemented for enum type columns. Remember, the methods set() and enum() can be used interchangebly for either I<set> or I<enum> type columns. The class doesn't make any distinction over the two type. It's the programmer's responsibility instead

=item C<extra($column_name)>

returns extra information about the $column_name. If no such information available, returns I<undef> instead. As of MySql 3.23.x, the only value extra() returns is I<auto_increment>

=item C<load_default($CGI)>

loads defaults of the columns into the CGI.pm object. It is usefull if you are making extensive use of Lincoln Stein's CGI.pm module.

=item C<validate($CGI)>

validates matching the value(s) of the paramaters with their respective columns (if exists) off the mysql table. This feature is not implemented as of MySQL::TableInfo version 0.03. Any modifications are welcome.

=back

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=head1 BUGS

No bugs have been detected thus far. Any bug reports should be sent to Sherzod Ruzmetov (sherzodR) <sherzodr@cpan.org>

=head1 SEE ALSO

L<DBI> L<DBD::mysql> L<CGI>

=cut
