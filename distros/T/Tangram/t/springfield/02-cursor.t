

use strict;
use lib "t/springfield";
use Springfield;

my @kids = qw( Bart Lisa Maggie );
my @population = sort qw( Homer Marge ), @kids;
my $children = 'children';

sub NaturalPerson::children
{
   my ($self) = @_;
   return wantarray ? @{ $self->{$children} }
      : join(' ', map { $_->{firstName} } @{ $self->{$children} } )
}

Springfield::begin_tests(15);

{
	my $storage = Springfield::connect_empty;

	my @children = map { NaturalPerson->new( firstName => $_, name => 'Simpson' ) } @kids;

	my $homer = NaturalPerson->new( firstName => 'Homer', name => 'Simpson',
									$children => [ @children ] );

	my $marge = NaturalPerson->new(firstName => 'Marge', name => 'Simpson',
								   $children => [ @children ] );

	$homer->{partner} = $marge;
	$marge->{partner} = $homer;

	$storage->insert( $homer, $marge );

	delete $homer->{partner};

	$storage->disconnect;
}

Springfield::leaktest;

{
   my $storage = Springfield::connect;

   my $cursor = $storage->cursor( 'NaturalPerson' );
   my @results;

   while (my $person = $cursor->current())
   {
      push @results, $person->{firstName};
      Springfield::test( $person->children eq "@kids" ) if $person->{firstName} eq 'Homer';
      $cursor->next();
   }

   @results = sort @results;

   Springfield::test( "@results" eq "@population" );

   $storage->disconnect;
}

Springfield::leaktest;

{
   my $storage = Springfield::connect;

   my $cursor1 = $storage->cursor( 'NaturalPerson' );
   my $cursor2 = $storage->cursor( 'NaturalPerson' );
   
   my (@r1, @r2);

   while ($cursor1->current())
   {
      my $p1 = $cursor1->current();
      my $p2 = $cursor2->current();
      
      push @r1, $p1->{firstName};
      push @r2, $p2->{firstName};

      Springfield::test( $p1->children eq "@kids" ) if $p1->{firstName} eq 'Homer';
      Springfield::test( $p2->children eq "@kids" ) if $p2->{firstName} eq 'Marge';

      $cursor1->next();
      $cursor2->next();
   }

   @r1 = sort @r1;
   @r2 = sort @r2;

   Springfield::test( "@r1" eq "@population" && "@r2" eq "@population" );

   $storage->disconnect;
}

Springfield::leaktest;

{
	my $storage = Springfield::connect;
	$storage->insert( NaturalPerson->new(firstName => 'Montgomery',	name => 'Burns' ) );
	$storage->disconnect;
}

{
   my $storage = Springfield::connect;

   my $remote = $storage->remote('NaturalPerson');

   my @results = $storage->select($remote,
	   order => [ $remote->{firstName}, $remote->{name} ] );

   @results = map { "$_->{firstName} $_->{name}"} @results;

   Springfield::test( "@results\n" eq <<CONTROL );
Bart Simpson Homer Simpson Lisa Simpson Maggie Simpson Marge Simpson Montgomery Burns
CONTROL

   $storage->disconnect;
}

{
   my $storage = Springfield::connect;

   my $remote = $storage->remote('NaturalPerson');

   my @results = $storage->select($remote,
       filter => $remote->{name} eq 'Simpson', 
	   order => [ $remote->{firstName}, $remote->{name} ] );

   @results = map { "$_->{firstName} $_->{name}"} @results;

   Springfield::test( "@results\n" eq <<CONTROL );
Bart Simpson Homer Simpson Lisa Simpson Maggie Simpson Marge Simpson
CONTROL

   $storage->disconnect;
}


Springfield::leaktest;

{
   my $storage = Springfield::connect;

   my ($person, $partner) = $storage->remote(qw( NaturalPerson NaturalPerson ));

   my $cursor = $storage->cursor($person,
       filter => $person->{partner} == $partner,
	   order => [ $partner->{firstName} ],
	   retrieve => [ $partner->{firstName}, $partner->{name} ]
	);

   my @results;

   while (my $p = $cursor->current())
   {
      push @results, $p->{firstName}, $cursor->residue();
      $cursor->next();
   }

   # print "@results\n";

   Springfield::test( "@results" eq 'Marge Homer Simpson Homer Marge Simpson');

   $storage->disconnect;
}

Springfield::leaktest;

{
   my $storage = Springfield::connect;

   my ($person, $partner) = $storage->remote(qw( NaturalPerson NaturalPerson ));

   my $cursor = $storage->cursor($person,
       filter => $person->{partner} == $partner,

	   # here we're ordering by an unselected foreign column; MySQL doesn't
           # mind, some other RDBMS' apparently do.
           # This extra column will end up in the $cursor->residue();
	   order => [ $partner->{firstName} ],
	);

   my @results;

   while (my $p = $cursor->current())
   {
      push @results, $p->{firstName}, $cursor->residue();
      $cursor->next();
   }

   # print "@results\n";

   Springfield::test( "@results" eq 'Marge Homer Homer Marge');

   $storage->disconnect;
}

Springfield::leaktest;

#{
#  my $storage = Springfield::connect;

#  my ($person) = $storage->remote(qw( NaturalPerson ));

#  my $cursor = $storage->cursor($person, limit => 1);

#  Springfield::test( $cursor->current() && !$cursor->next());

#  $storage->disconnect;
#}

#Springfield::leaktest;
