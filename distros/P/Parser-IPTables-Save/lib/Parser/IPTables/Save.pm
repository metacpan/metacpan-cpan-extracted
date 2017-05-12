package Parser::IPTables::Save;

use warnings;
use strict;

use Carp qw/ croak /;
use Tie::File;


=head1 NAME

Parser::IPTables::Save - A parser for iptables-save output files.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Parser::IPTables::Save;

	my $iptables_save = Parser::IPTables::Save->new('/tmp/iptables.out');
	$iptables_save->table('filter');

	$iptables_save->create({ chain => 'POSTROUTING', source => '192.168.1.0/24', target => 'MASQUERADE', comment => 'Rule to masquerade' });

	$iptables_save->move(3, -1);

	$iptables_save->delete(8);
	$iptables_save->delete(9);

	my @rules = $iptables_save->fetch_rules();

	$iptables_save->disable(10);
	$iptables_save->enable(10);

	$iptables_save->save();


=head1 METHODS

=head2 create

Create a new rule

	$iptables_save->create({ chain => 'POSTROUTING', source => '192.168.1.0/24', target => 'MASQUERADE', comment => 'Rule to masquerade' });

=cut

sub create {
	my($self, $rule, $index) = @_;

	if($index) {
		# replace
		splice(@{ $self->{rules}}, $index, 0, ($rule));
	}
	else {
		unshift(@{ $self->{rules} }, $rule);
	}
}


=head2 delete

Delete a rule

	$iptables_save->delete(8);

=cut

sub delete {

	my($self, $index) = @_;

	delete @{ $self->{rules}}[$index];
}


=head2 disable

disable a rule

	# disable rule with index 5
	$iptables_save->disable(5);

=cut

sub disable {

	my($self, $index) = @_;

	@{ $self->{rules}}[$index]->{disabled} = 1;

	return;

}


=head2 enable

enable a rule

	# enable a rule previously disabled
	$iptables_save->enable(5);

=cut

sub enable {

	my($self, $index) = @_;

	@{ $self->{rules}}[$index]->{disabled} = 0;

	return;

}


=head2 new

=cut

sub new {

	my($proto, $iptables_save_file) = @_;

	unless( $proto && defined($iptables_save_file) ) { croak "Parser::IPTables::Save->new(): usage error"; }

    my $class = ref($proto) || $proto;

	my $self = {};

	# open iptables-save output file
	tie my @file_array, 'Tie::File', $iptables_save_file or croak("Error opening file $iptables_save_file $!");

	$self->{file_array} = \@file_array;

    bless($self, $class);

	return $self;

}


=head2 table

Set table name

	$iptables_save->table('filter');

=cut

sub table {

	my($self, $table_name) = @_;

	# set table name
	$self->{table_name} = $table_name;

	my $get_lines = 0;
	my @rules;

	# set line of 
	my $i = 0;

	foreach my $line (@{ $self->{file_array} }) {

		if($line eq '*'.$self->{table_name}) { 
			$get_lines = 1; 
			$self->{initial_line} = ($i + 1);
			next; 
		}

		# packet counters
		if($get_lines == 1 && substr($line, 0, 1) eq ':') {
			$self->{initial_line}++;
		}
		elsif($get_lines == 1 && (substr($line, 0, 2) eq '-A' || substr($line, 0, 3) eq '#-A')) {

			my $rule = {};

			# if rule is disabled
			$rule->{disabled} = 1 if(substr($line, 0, 1) eq '#');

			# chain
			$rule->{chain} = $1 if($line =~ /-A\s+([\w]+)/g);

			# protocol
			if($line =~ /-p\s+([\!\w\d]+)/g) {
				$rule->{proto} = $1;

				# when get only ! character
				if($rule->{proto} =~ /^\!$/) {
 					$rule->{proto} = '! '.$1 if($line =~ /-p\s+\!\s+([\!\w\d]+)/);
				}
			}

			# module
			my @modules;
			while($line =~ /-m\s+([\w\d]+)/g) {
				push(@modules, $1);
			}
			$rule->{module} = \@modules;

			# source
			if($line =~ /-s\s+([\w\d\!\-\.\/]+)/g) {
				$rule->{source} = $1;

				# when get only ! character
				if($rule->{source} =~ /^\!$/) {
 					$rule->{source} = '! '.$1 if($line =~ /-s\s+\!\s+([\w\d\!\-\.\/]+)/);
				} 
			}

			# destination
			if($line =~ /-d\s+([\w\d\!\-\.\/]+)/g) {
				$rule->{destination} = $1; 

				# when get only ! character
				if($rule->{destination} =~ /^\!$/) {
 					$rule->{destination} = '! '.$1 if($line =~ /-d\s+\!\s+([\w\d\!\-\.\/]+)/);
				} 
			}

			# state
			if($line =~ /--state\s+(\w+)/g) {
				$rule->{state} = $1;
			}

			# source port
			if($line =~ /--sport\s+([\w\:]+)/g) {
				$rule->{port_source} = $1;

				# when get only ! character
				if($rule->{port_source} =~ /^\!$/) {
 					$rule->{port_source} = '! '.$1 if($line =~ /-d\s+\!\s+([\w\:]+)/);
				} 
			}

			# destination port
			if($line =~ /--dport\s+([\w\:]+)/g) {
				$rule->{port_destination} = $1;

				# when get only ! character
				if($rule->{port_destination} =~ /^\!$/) {
 					$rule->{port_destination} = '! '.$1 if($line =~ /-d\s+\!\s+([\w\:]+)/);
				} 
			}


			# target
			$rule->{target} = $1 if($line =~ /-j\s+([\w]+)/);

			# target param1
			$rule->{target_param1} = $2 if($line =~ /-j\s+(.*?)\s+([\w\-]*)/);

			# target param2
			$rule->{target_param2} = $3 if($line =~ /-j\s+(.*?)\s+([\w\-]*)\s+([\w\-\.\:]*)/);


			# prevent target_param1 and targer_param2 from get --comment
			if($rule->{target_param1} && $rule->{target_param1} eq '--comment') {
				$rule->{target_param1} = '';
				$rule->{target_param2} = '';
			}


			# comment
			$rule->{comment} = $1 if($line =~ /--comment\s+\"(.*)\"/);


			push(@rules, $rule);

		}

		last if($get_lines == 1 && $line eq 'COMMIT');

		$i++;

	}

	# number of rules
	$self->{number_of_rules} = @rules;

	# save rules on object
	$self->{rules} = \@rules;

	return $self->{table_name} if($self->{table_name});

	return 0;

}


=head2 fetch_rules

=cut

sub fetch_rules {

	my $self = shift;

	croak("You need set a table name: \$obj->table('tablename');") if(! $self->{table_name});

	# set index foreach row
	my @trules;
	my $i = 0;
	foreach my $row (@{ $self->{rules} }) {

		$row->{id} = $i;
		$i++;

		push(@trules, $row);

	}

	# save trules on object
	$self->{rules} = \@trules;

	# if wants a array
	return @{ $self->{rules} } if wantarray();

	# if wants a arrayref
	return $self->{rules};

}


=head2 DESTROY

=cut

sub DESTROY {
	my $self = shift;	
	untie $self->{file_array};
}


=head2 move

Move rules 

	# Move rule of index 1, 3 positions down
	$iptables_save->move(1, 3);

=cut

sub move {

	my($self, $index, $move) = @_;

	# Get rule
	my $rule = @{ $self->{rules}}[$index];

	# Prevent eg: index 0, move -1
	if($move < 0) {
		$move *= -1;
		return if(($index - $move) < 0);
	}

	# delete rule on current position
	delete @{ $self->{rules}}[$index];

	# prevent erro where $move > 0
	$move++ if($move > 0);

	# replace
	splice(@{ $self->{rules}}, ($index + $move), 0, ($rule));

}


=head2 save

	$iptables_save->save();

=cut

sub save {
	my $self = shift;

	my @trules;

	foreach my $rule (@{ $self->{rules} }) {

		# if deleted rule
		next if(!$rule);

		# Mount rule
		my $str_rule = '';

		# if rule is disabled
		$str_rule .= '#' if($rule->{disabled});

		# chain
		$str_rule .= '-A '.$rule->{chain}.' '; 

		# protocol
		$str_rule .= '-p '.$rule->{proto}.' ' if($rule->{proto}); 

		# modules
		foreach my $module (@{ $rule->{module} }) {
			$str_rule .= '-m '.$module.' ';
		}

		# interface input
		$str_rule .= '-i '.$rule->{iface_input}.' ' if($rule->{iface_input});

		# interface output
		$str_rule .= '-o '.$rule->{iface_output}.' ' if($rule->{iface_output});

		# source
		$str_rule .= '-s '.$rule->{source}.' ' if($rule->{source});

 		# destination
		$str_rule .= '-d '.$rule->{destination}.' ' if($rule->{destination}); 

 		# state
		$str_rule .= '--state '.$rule->{state}.' ' if($rule->{state});

		# source port
		$str_rule .= '--sport '.$rule->{port_source}.' ' if($rule->{port_source}); 

		# destination port
		$str_rule .= '--dport '.$rule->{port_destination}.' ' if($rule->{port_destination}); 

		# target
		$str_rule .= '-j '.$rule->{target}.' ' if($rule->{target}); 

		# target param1
		$str_rule .= $rule->{target_param1}.' ' if($rule->{target_param1});

 		# target param2
		$str_rule .= $rule->{target_param2}.' ' if($rule->{target_param2});

 		# comment
		$str_rule .= '--comment "'.$rule->{comment}.'" ' if($rule->{comment}); 

		push(@trules, $str_rule);
	}

	splice(@{ $self->{file_array} }, $self->{initial_line}, $self->{number_of_rules}, @trules);

}


=head1 AUTHOR

Geovanny Junio, C<< <geovannyjs at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parser-iptables-save at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parser-IPTables-Save>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parser::IPTables::Save


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parser-IPTables-Save>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parser-IPTables-Save>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parser-IPTables-Save>

=item * Search CPAN

L<http://search.cpan.org/dist/Parser-IPTables-Save/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Geovanny Junio.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Parser::IPTables::Save
