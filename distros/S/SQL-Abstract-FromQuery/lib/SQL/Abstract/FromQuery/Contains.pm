package SQL::Abstract::FromQuery::Contains;

use strict;
use warnings;
use parent 'SQL::Abstract::FromQuery';


# add a 'contains' rule into the grammar
{
  use Regexp::Grammars;

  return qr{

    <grammar: SQL::Abstract::FromQuery::Contains>

    <extends: SQL::Abstract::FromQuery>

    <rule: contains>
       <[string]>+ % <word_sep>

    <rule: contains_any>
       <[string]>+ % <word_sep>

    <token: word_sep>
       [,\s]+
  }xms;
};


#======================================================================
# CLASS METHODS
#======================================================================

sub sub_grammar {
  my $class = shift;
  return ('SQL::Abstract::FromQuery::Contains');
}


#======================================================================
# ACTIONS HOOKED TO THE GRAMMAR
#======================================================================

sub contains {
  my ($self, $h) = @_;
  return {-contains => $h->{string}};
}

sub contains_any {
  my ($self, $h) = @_;
  return {-contains_any => $h->{string}};
}


#======================================================================
1; # End of SQL::Abstract::FromQuery::Contains
#======================================================================

__END__


=head1 NAME

SQL::Abstract::FromQuery::Contains - SQL::Abstract::FromQuery extension for a 'contains' rule


=head1 SYNOPSIS

  my $parser = SQL::Abstract::FromQuery->new(
    -components => [qw/Contains/],
    -fields => {
       contains => [qw/fulltext1 fulltext2/],
     }
  );

=head1 DESCRIPTION

This component adds rules C<contains> and C<contains_any> to the root
grammar. The purpose is to generate fulltext queries to the database
on some specific fields.  Fields associated to such rules will
generate structures of shape

  {-contains => $list_of_words }
  # or
  {-contains_any => $list_of_words }

This is meant to work in collaboration with 
L<SQL::Abstract/"SPECIAL OPERATORS">. So the job of the present module 
is only to mark the query on this field as a fulltext query; then you
should define a special operator named C<-contains> within 
your L<SQL::Abstract> instance, so that this can be translated to appropriate
SQL for your database.

=head1 AUTHOR

Laurent Dami, C<< <laurent.dami AT justice.ge.ch> >>

=cut


