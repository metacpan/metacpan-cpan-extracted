package SQL::Library;

use strict;
use warnings;

our $VERSION = '0.0.5';

sub new
{
    my $proto = shift; 
    my $options = shift;
    my $self = {
                 'options'  => $options,
                 'contents' => undef
               };

    my $curr_name = '';

    my @lib_arr = ();
    if ( ref $self->{'options'}->{'lib'} eq 'ARRAY' )
    {
        # Could be a filehandle or a string.
        if ( @{ $self->{'options'}->{'lib'} } == 1 )
        {
            @lib_arr = split /(?<=\n)/, $self->{'options'}->{'lib'}->[0];
        }
        else
        {
            @lib_arr = @{ $self->{'options'}->{'lib'} };
        }
    }
    else
    {
        open LIB, $self->{'options'}->{'lib'}
          or die "Cannot open $self->{'options'}->{'lib'}: $!";
        @lib_arr = <LIB>;
        close LIB;
    }

    foreach ( @lib_arr )
    {
        next if m{^\s*$};
        next if m{^\s*#};
        next if m{^\s*//};
        if ( m{^\[([^\]]+)\]} )
        {
            $curr_name = $1;
            next;
        }
        if ( $curr_name )
        {
            $self->{'contents'}->{$curr_name} .= $_;
        }
    }

    bless $self, $proto;
    return $self;
}

sub retr
{
    my ( $self, $entity_name ) = @_;
    return $self->{'contents'}->{$entity_name};
}

sub set
{
    my ( $self, $entity_name, $entity ) = @_;
    $self->{'contents'}->{$entity_name} = $entity;
    return $self;
}

sub drop
{
    my ( $self, $entity_name ) = @_;
    delete $self->{'contents'}->{$entity_name};
    return $self;
}

sub elements
{
    my $self = shift;
    return sort keys %{$self->{'contents'}};
}

sub dump
{
    my $self   = shift;
    my $output = '';
    foreach ( sort keys %{$self->{'contents'}} )
    {
        $output .= sprintf "[%s]\n%s\n", $_, $self->{'contents'}->{$_};
    }
    return $output;
}

sub write
{
    my $self = shift;
    open OUT, ">$self->{'options'}->{'lib'}"
      or die "Cannot open $self->{'options'}->{'lib'}: $!";
    print OUT $self->dump;
    close OUT;
}

1 ;
__END__

=pod

=head1 NAME

SQL::Library - A module for managing simple SQL libraries
stored in INI-like files.

=head1 VERSION

This document refers to version 0.0.5 of SQL::Library.

=head1 SYNOPSIS

  use SQL::Library;
    
  my $sql = new SQL::Library { lib => 'sql.lib' };
                        # or { lib => [ <FH> ] };
                        # or { lib => [ $string ] };

  ## Ask for a library entry by name...
  my $query = $sql->retr( 'some_sql_query' );

  ## Add or update an entry...
  $sql->set( 'yet_another_query', <<'END' );
  SELECT foo
  FROM   bar
  WHERE  zoot = 1
  END

  ## Remove an entry from the library...
  $sql->drop( 'one_more_query' );

  ## List the entries in the library...
  print join( ' : ', $sql->elements ), "\n";

  ## Dump the contents of the library to a string...
  my $lib_str = $sql->dump;

  ## Write the library to disk...
  $sql->write;

=head1 LIBRARY FILE FORMAT

The format for the library files looks a little like an INI file.
However, unlike an INI file, it does not handle key=value pairs
which are divided into sections.  Library entry names are on a line by
themselves, enclosed in square brackets.  Whatever occurs until the
next title tag is the value of the library entry.  Blank lines, pound
signs (#) and C++ style comments (//) are all discarded.

A sample library file might look like this:

  ## A sample library file

  [get_survey_questions]
  select   question_no,
           question_text
  from     question
  where    survey_id = ?
  order by question_no

  [get_survey_info]
  select title,
         date_format( open_date, '%Y%m%d' ) as open_date, 
         date_format( close_date, '%Y%m%d' ) as close_date, 
         template_file
  from   survey
  where  survey_id = ?

=head1 OBJECT METHODS

=over 4

=item PACKAGE-E<gt>new( HASHREF )

Create a new library handle.  Currently, the only argument supported in
the hashref is C<lib>, which refers to the file containing the SQL
library.

=item $OBJ-E<gt>retr( NAME )

Returns the library entry referenced by NAME.

=item $OBJ-E<gt>set( NAME, VALUE )

Sets the library entry NAME to VALUE.  This is used both to create new
library entries and to update existing ones.

=item $OBJ-E<gt>drop( NAME )

Drops entry NAME form the library.

=item $OBJ-E<gt>elements

Returns a list of all entry names in the library.

=item $OBJ-E<gt>dump

Returns a string containing the library contents in the same
INI format that the module reads from.

=item $OBJ-E<gt>write

Writes the library to the file named in C<lib>.

=back

=head1 BUGS

=over 4

=item *

write() should write to a string, if it was so called.

=back

=head1 TO-DO

=over 4

=item *

Complete test suite

=back

=head1 AUTHOR

Doug Gorley E<lt>douggorley@shaw.caE<gt>

=head1 CO-MAINTAINER

Chris Vertonghen E<lt>chrisv@cpan.orgE<gt> (post-0.0.3)

=head1 COPYRIGHT & LICENSE

Copyright (C) 2004 by Doug Gorley.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
