#!/usr/bin/perl

use DBI;
use Relations;
use Relations::Query;
use lib '.';
use Relations::Family;
use Relations::Family::Member;
use Relations::Family::Lineage;
use Relations::Family::Rivalry;

use finder;

configure_settings('fam_demo','root','','localhost','3306') unless -e "Settings.pm";

eval "use Settings";

$dsn = "DBI:mysql:mysql:$host:$port";

$dbh = DBI->connect($dsn,$username,$password,{PrintError => 1, RaiseError => 0});

$abs = new Relations::Abstract($dbh);

create_finder($abs,$database);
$finder = relate_finder($abs,$database);

print "
  Greetings! This is demo for Relations::Family module. Check out
  the help for Relations::Family (man,pod,html) to see how to use
  it since it is a bit complicated.

";

do {

  print "Finder Members:\n\n";

  $x = 0;

  foreach $member (@{$finder->{members}}) {

    print "  ($x) $member->{label}\n";
    $x++;

  }

  $mem = get_input("\nWhich Member would you like to View? (#) [0]\n");

  $beg_chosen = $finder->get_chosen($member => $finder->{members}->[$mem]);

  $choose = get_input("\nChoose Available? (Y/N) [N]\n");

  if ($choose =~ /y/i) {

    $chosen = $finder->choose_available($member => $finder->{members}->[$mem]);

    $mid_chosen = $finder->get_chosen($member => $finder->{members}->[$mem]);

    print "Narrowed $beg_chosen->{count} choices to $mid_chosen->{count}\n";

  }

  $limit = get_input("Limit (total or start,total)? [none]\n");
  $filter = get_input("Filter (Enter Text)? [none]\n");

  $finder->set_chosen(-label  => $finder->{members}->[$mem]->{label},
                      -ids    => $finder->{members}->[$mem]->{chosen_ids_string},
                      -match  => $finder->{members}->[$mem]->{match},
                      -group  => $finder->{members}->[$mem]->{group},
                      -ignore => $finder->{members}->[$mem]->{ignore},
                      -limit  => $limit,
                      -filter => $filter);

  print "\nAvailable Records for '$finder->{members}->[$mem]->{label}'\n\n";

  %chosen_ids = ();

  foreach $id (@{$finder->{members}->[$mem]->{chosen_ids_array}}) {

    $chosen_ids{$id} = 1;

  }

  $available = $finder->get_available(-member => $finder->{members}->[$mem]);

  foreach $id (@{$available->{ids_array}}) {

    $spark = $chosen_ids{$id} ? '*' : ' ';

    print " $spark ($id)\t$available->{labels_hash}->{$id}\n";

  }

  print "  Match: $available->{match} ";
  print "Group: $available->{group}\n";
  print "  Limit: $available->{limit} ";
  print "Filter: $available->{filter}\n";

  $ids = get_input("Selections (separate with ',')? [none]\n");
  $match = get_input("Match (0/1)? [0]\n");
  $group = get_input("Group (0/1)? [0]\n");

  $finder->set_chosen(-label  => $finder->{members}->[$mem]->{label},
                      -ids    => $ids,
                      -match  => $match,
                      -group  => $group,
                      -limit  => $limit,
                      -filter => $filter);

  $again = get_input("\nAgain? (Y/N) [Y]\n");

} until ($again =~ /n/i);

$reunion = get_input("\nCreate Reunion? (Y/N) [N]\n");

exit unless ($reunion =~ /y/i);

@values = keys %{$finder->{'values'}};
@values = sort @values;

print "Finder Values:\n\n";

$x = 0;

foreach $value (@values) {

  print "  ($x) $value\n";
  $x++;

}

$data = get_input("Data (separate with ',') (#) ?\n");
$group_by = get_input("Group By (separate with ',') (#) ?\n");
$order_by = get_input("Order By (separate with ',') (#) ?\n");

print "Finder Members:\n\n";

$x = 0;

foreach $member (@{$finder->{members}}) {

  print "  ($x) $member->{label}\n";
  $x++;

}

$ids = get_input("Use Chosen from (separate with ',') (#) ?\n");

@data = ();
@ids = ();
@group_by = ();
@order_by = ();

@data_nums = split /,/, $data;
@ids_nums = split /,/, $ids;
@group_by_nums = split /,/, $group_by;
@order_by_nums = split /,/, $order_by;

foreach $data_num (@data_nums) {

  push @data, $values[$data_num];

}

foreach $ids_num (@ids_nums) {

  push @ids, $finder->{members}->[$ids_num]->{name};

}

foreach $group_by_num (@group_by_nums) {

  push @group_by, $values[$group_by_num];

}

foreach $order_by_num (@order_by_nums) {

  push @order_by, $values[$order_by_num];

}

$reunion = $finder->get_reunion(-data      => \@data,
                                -use_names => \@ids,
                                -group_by  => \@group_by,
                                -order_by  => \@order_by);

$matrix = $abs->select_matrix(-query => $reunion);

@names = keys %{$matrix->[0]};

foreach $row (@$matrix) {

  foreach $name (@names) {

    print "  $name: $row->{$name}\n";

  }

  print "\n";

}

sub get_input {

  $question = shift;

  print $question;

  $input = <STDIN>;

  chomp $input;

  return $input;

}

