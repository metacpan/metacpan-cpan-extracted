#!/usr/bin/perl
package SQL::QueryBuilder::Pretty;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(croak);
use Data::Dumper;

use Module::Pluggable 
    'search_path' => [ 
        'SQL::QueryBuilder::Pretty::Database::ANSI',
    ],
    'instantiate' => 'new',
    'sub_name'    => 'rules'
;
use SQL::QueryBuilder::Pretty::Print;

sub new {
    my $class = shift;
    my %self  = @_;

    if ( my $database = delete $self{'-database'} ) {
        $class = CORE::join( q{::}, $class, 'Database', $database );
        eval "use $class; 1" or croak $@;
        return $class->new( %self );
    }
    elsif ( my $handler = delete $self{'-handler'} ) {
        $class = CORE::join( q{::}, $class, 'Handler', ref $handler );
        eval "use $class; 1" or croak $@;
        return $class->new( %self, 'handler' => $handler );
    } 
    else {
        return bless { %self }, ref $class || $class;
    }
}

sub print {
    my $self  = shift;
    my $query = shift;

    # Initializes the print object
    my $print = SQL::QueryBuilder::Pretty::Print->new( %{ $self } );

    # Get rules in the correct order
    # TODO: load unique rules by name
    my @rules = sort { $a->order <=> $b->order } $self->rules();

    while ( $query ) {
        for my $rule ( @rules ) {
            my $match = $rule->match;

            if ( $query =~ s/^($match)//smx ) {
                # A rule can exit in error, in that case continue trying
                last if $rule->action($print, $1);
            }
        }
    }

    return $print->query;
}

1;
__END__
=head1 NAME

SQL::QueryBuilder::Pretty - Perl extension to beautify SQL.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use SQL::QueryBuilder::Pretty;

    my $pretty = SQL::QueryBuilder::Pretty->new(
        '-indent_ammount' => 4,
        '-indent_char'    => ' ',
        '-new_line'       => "\n",
    );

    print $pretty->print('SELECT * FROM table WHERE col1 = NOW()');

=head1 DESCRIPTION

The main goal of this Module was not the beautify mechanism, wich is allready
well implemented in L<SQL::Beautify>, but to provide a easy way to add
new SQL languages, and related rules, in a modular and independent fashion.

=head2 METHODS

=over 4

=item I<PACKAGE>->new(I<%options>)

Initializes the object.

=item I<$obj>->print(I<$query>)

Returns a beautifyed SQL query.

=back

=head2 OPTIONS

=over 4

=item -database

The database rules to apply to the query. C<SQL::QueryBuilder::Pretty-E<gt>new( 
'-database' => 'MySQL' )> is the same as 
C<SQL::QueryBuilder::Pretty::Database::MySQL-E<gt>new()>>. Default is none.

=item -handler

The database rules to apply to the query. C<SQL::QueryBuilder::Pretty-E<gt>new( 
'-handler' => $dbh_mysql )> is the same as 
C<SQL::QueryBuilder::Pretty::Handler::DBD::db::mysql-E<gt>new()>>. Default is none.

=item -indent_amount

The number of time '-indent_char' is repeated for each indentation. Default is 4.

=item -indent_char 

Indent char used. Default is ' '.

=item -new_line

New line char used. default is "\n", 

=back

=head2 ADDING RULES FOR A SPECIFIC DATABASE

If the database option is not set, SQL::QueryBuilder::Pretty will use ANSI rules to
beautify the query. This rules can be found in 
SQL/QueryBuilder/Pretty/Database/ANSI/*.

Let's imagine we wanted to create the rules for Oracle database:

=over 4

In SQL/QueryBuilder/Pretty/Database we should add the file Oracle.pm with the 
following code:

    #!/usr/bin/perl
    package SQL::QueryBuilder::Pretty::Database::Oracle;
    use base qw(SQL::QueryBuilder::Pretty);

    SQL::QueryBuilder::Pretty->search_path( 
        add => 'SQL::QueryBuilder::Pretty::Database::Oracle'
    );

    1;

Create the Oracle's rules directory SQL/QueryBuilder/Pretty/Database/Oracle and 
add the necessary rules. See SUBCLASSING in L<SQL::QueryBuilder::Pretty::Rule>.

=back

=head2 ADDING A NEW HANDLER SUPPORT

TO add a new handler support we need to first add the related database. 
See ADDING RULES FOR A SPECIFIC DATABASE.

Let's imagine we wanted to create the support for DBI::oracle handler:

=over 4

Get the reference of the handler. In DBI's case it's DBI::db.

If not exists, create the directory SQL/QueryBuilder/Pretty/Handler/DBI and
add the file db.pm with the following code:

    #!/usr/bin/perl
    package SQL::QueryBuilder::Pretty::Handler::DBI::db;

    sub new {
        my $class = shift;
        my %self  = @_;

        if ( $self->{'handler'}->{'Driver'}->{'Name'} eq 'oracle' ) {
            return SQL::QueryBuilder::Pretty::Database::Oracle->( %self );
        }
    } 

    1;

This is just an example of what can be done.

=back

=head1 ACKNOWLEDGEMENTS

Although L<SQL::QueryBuilder::Pretty> have a differente approach, some ideas where
"borrowed" from other projects. That said ,I would like to thank to:

=over 4

Igor Sutton Lopes, for L<SQL::Tokenizer>, where I got must of the regular
expressions used in SQL::QueryBuilder::Pretty's rules;

Jonas Kramer, for L<SQL::Beautify>, where I got the idea for the output 
manipultaion system used in L<SQL::QueryBuilder::Pretty::Print>.

=back

A special thank to Marco Neves who encourage me to make this distribuition
available in CPAN.

=head1 SEE ALSO

L<SQL::QueryBuilder>, L<Module::Pluggable>, L<SQL::Tokenizer> and 
L<SQL::Beautify>.

=head1 AUTHOR

André Rivotti Casimiro, C<< <rivotti at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-sql-querybuilder-pretty at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQL-QueryBuilder-Pretty>. 
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SQL::QueryBuilder::Pretty

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SQL-QueryBuilder-Pretty>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SQL-QueryBuilder-Pretty>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SQL-QueryBuilder-Pretty>

=item * Search CPAN

L<http://search.cpan.org/dist/SQL-QueryBuilder-Pretty>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by André Rivotti Casimiro. Published under the terms of 
the Artistic License 2.0.

=cut
