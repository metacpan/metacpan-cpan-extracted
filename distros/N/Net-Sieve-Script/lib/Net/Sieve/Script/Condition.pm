package Net::Sieve::Script::Condition;
use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use vars qw($VERSION);

$VERSION = '0.08';

__PACKAGE__->mk_accessors(qw(test not id condition parent AllConds key_list header_list address_part match_type comparator require));

my @FILO;
my $ids = 0;
my %Conditions;

sub new
{
    my ($class, $param) = @_;

    my $self = bless ({}, ref ($class) || $class);
	my $require;

    my @ADDRESS_PART = qw((:all |:localpart |:domain ));
    #Syntax:   ":comparator" <comparator-name: string>
    my @COMPARATOR_NAME = qw(i;octet|i;ascii-casemap);
    # my @MATCH_TYPE = qw((:\w+ ));
	# regex expired draft will be removed
    my @MATCH_TYPE = qw((:is |:contains |:matches ));
    my @MATCH_SIZE = qw((:over |:under ));
    # match relationnal RFC 5231
	my @MATCH_REL = qw((:value .*? |:count .*? ));
    # match : <header-list: string-list> <key-list: string-list>
    my @LISTS = qw((\[.*?\]|".*?"));

    #my @header_list = qw(From To Cc Bcc Sender Resent-From Resent-To List-Id);

    $param =~ s/\t/ /g;
    $param =~ s/\s+/ /g;
    $param =~ s/^\s+//;
    $param =~ s/\s+$//;
    $param =~ s/[\r\n]//gs;

    return undef if 
        $param !~ m/^(not )?(address|envelope|header|size|allof|anyof|exists|false|true)(.*)/i;

    my $not = lc($1);
    my $test = lc($2);
    my $args = $3;

    $self->not($not);
    $self->test($test);

    # to manage tree access
    $ids++;
    $self->id($ids);
    $Conditions{$ids} = $self;
    $self->AllConds(\%Conditions);

    # clean args
    $args =~ s/^\s+//g;
    $args =~ s/\s+$//g;
    $args =~ s/\s+(\s+[\(\)],?\s+)\s+/$1/g;

    # substitute ',' separator by ' ' in string-list
    # to easy parse test-list
    # better :  
    1 while ($args =~ s/(\[[^\]]+?)",\s*/$1" /);
    #$args =~ s/",\s+"/" "/g;

    #recursiv search for anyof/allof conditions
    my @COND = $self->condition(); 
	my $count;
    while ( $args =~ s/(.*)\(([^\(].*?)\)(.*)/$1$3/s ) { 
        my $first = $1;
        my $last = $3;
        my $subs = $2;

        $count++;
		die "50 test lists does not sound reasonable !"
              if ( $count >= 50);

        my @condition_list;
        my @condition_list_string = split ( ',', $subs );
        foreach my $sub_condition (@condition_list_string) {
            my $new_subs = Net::Sieve::Script::Condition->new($sub_condition);
            next if (!$new_subs);
            if ( $new_subs->test eq 'anyof' || $new_subs->test eq 'allof' ) {
                my $child_tab = pop @FILO;
                $new_subs->condition($child_tab);
                # set parent infos for tree management
                foreach my $child ( @{$child_tab} ) {
                    $child->parent($new_subs);
                }
            };
            (!$first && !$last) ? 
               push @COND, $new_subs : push @condition_list, $new_subs;
        }
    
        (!$first && !$last) ? 
            $self->condition(\@COND) : push @FILO, \@condition_list;

    };
    # set parent infos for tree management
    foreach my $child ( @COND ) {
        $child->parent($self) if $child;
    } ;

    my ($address,$comparator,$match,$string,$key_list);
    # RFC Syntax : address [ADDRESS-PART] [COMPARATOR] [MATCH-TYPE]
    #             <header-list: string-list> <key-list: string-list>
    if ( $test eq 'address' ) {
      ($address,$comparator,$match,$string,$key_list) = $args =~ m/@ADDRESS_PART?(:comparator "(?:@COMPARATOR_NAME)" )?@MATCH_TYPE?@LISTS @LISTS$/gi;
    };
    # RFC Syntax : envelope [COMPARATOR] [ADDRESS-PART] [MATCH-TYPE]
    #             <envelope-part: string-list> <key-list: string-list>
    if ( $test eq 'envelope' ) {
      ($comparator,$address,$match,$string,$key_list) = $args =~ m/(:comparator "(?:@COMPARATOR_NAME)" )?@ADDRESS_PART?@MATCH_TYPE?@LISTS @LISTS$/gi;
    };
    # RFC Syntax : header [COMPARATOR] [MATCH-TYPE]
    #             <header-names: string-list> <key-list: string-list>
    if ( $test eq 'header' ) {
      # only for regex old draft
      ($match,$comparator,$string,$key_list) = $args =~ m/(:regex )?(:comparator "(?:@COMPARATOR_NAME)" )?@LISTS @LISTS$/gi;
      # match relationnal RFC 5231
	  if (!$match) {
        ($match,$comparator,$string,$key_list) = $args =~ m/@MATCH_REL?(:comparator "(?:@COMPARATOR_NAME)" )?@LISTS @LISTS$/gi;
	  };
      # RFC 5228 ! 
	  if (!$match) {
        ($comparator,$match,$string,$key_list) = $args =~ m/(:comparator "(?:@COMPARATOR_NAME)" )?@MATCH_TYPE?@LISTS @LISTS$/gi;
      }
	  if (!$match) {
        ($match,$comparator,$string,$key_list) = $args =~ m/@MATCH_TYPE?(:comparator "(?:@COMPARATOR_NAME)" )?@LISTS @LISTS$/gi;
      }
    };
    # RFC Syntax : size <":over" / ":under"> <limit: number>
    if ( $test eq 'size'  ) {
      ($match,$string) = $args =~ m/@MATCH_SIZE(.*)$/gi;
	};
	# RFC Syntax : exists <header-names: string-list>
	if ( $test eq 'exists' ) {
	  ($string) = $args =~ m/@LISTS$/gi; 
	}
    # find require
    if (lc($match) eq ':regex ') {
	  push @{$require}, 'regex';
	};
	$self->require($require);


    $self->address_part(lc($address));
    $self->match_type(lc($match));
    $self->comparator(lc($comparator));
    $self->header_list($string);
    $self->key_list($key_list);


    return $self;
}

# see head2 equals

sub equals {
	my $self = shift;
	my $object = shift;

	return 0 unless (defined $object);
	return 0 unless ($object->isa('Net::Sieve::Script::Condition'));

	# Should we test "id" ? Probably not it's internal to the
	# representaion of this object, and not a part of what actually makes
	# it a sieve "condition"

	my @accessors = qw( test not address_part match_type comparator require key_list header_list address_part );

	foreach my $accessor ( @accessors ) {
		my $myvalue = $self->$accessor;
		my $theirvalue = $object->$accessor;
		if (defined $myvalue) {
			return 0 unless (defined $theirvalue); 
            if ($accessor ne 'key_list') {
                $theirvalue=~tr/[A-Z]/[a-z]/; 
                $myvalue=~tr/[A-Z]/[a-z]/;
            };
			return 0 unless ($myvalue eq $theirvalue);
		} else {
			return 0 if (defined $theirvalue);
		}
	}

	if (defined $self->condition) {
		my $tmp = $self->condition;
		my @myconds = @$tmp;
		$tmp = $object->condition;
		my @theirconds = @$tmp;
		return 0 unless ($#myconds == $#theirconds);

		unless ($#myconds == -1) {
			foreach my $index (0..$#myconds) {
				my $mycond = $myconds[$index];
				my $theircond = $theirconds[$index];
				if (defined ($mycond)) {
					return 0 unless ($mycond->isa(
									'Net::Sieve::Script::Condition'));
					return 0 unless ($mycond->equals($theircond));
				} else {
					return 0 if (defined ($theircond));
				}
			}
		}

	} else {
		return 0 if (defined ($object->condition));
	}
	return 1;
}

# see head2 write

sub write {
    my $self = shift;
    my $recursiv_level = shift || 0;
    my $text_condition = "";

    $recursiv_level++;
    if (defined $self->condition() ) {
        $text_condition = ' ' x $recursiv_level;
        $text_condition .= $self->not.' ' if ($self->not);
        $text_condition .= $self->test." ( ";
        foreach my $sub_cond ( @{$self->condition()} ) {
            next if ! $sub_cond;
            if (defined $sub_cond->condition() ) {
                $text_condition .= "\n".(' ' x $recursiv_level).$sub_cond->write($recursiv_level).",\n";
                next;};
            $text_condition .= "\n".(' ' x $recursiv_level).'  '.  $sub_cond->_write_test().',';
        }
        $text_condition =~ s/,$//;
        $text_condition .= ' )';
    } 
    else {
        $text_condition = $self->_write_test();
    };

    return $text_condition;
}

# private method
# _write_test
# return single line text

sub _write_test {
    my $self = shift;
    my $line = $self->not.' '.$self->test.' ';
   
   my $comparator = ($self->comparator)?':comparator '.$self->comparator : '';
   
    if ( $self->test eq 'address' ) {
        $line .= $self->address_part.' '.$comparator.' '.$self->match_type;
    }
    elsif ( $self->test eq 'envelope' ) {
        $line .= $comparator.' '.$self->address_part.' '.$self->match_type;
    }
    elsif ( $self->test eq 'header' ) {
		if ($self->match_type eq ':regex ') {
            $line .= $self->match_type.' '.$self->comparator;
		}
		else {
            $line .= $self->comparator.' '.$self->match_type;
		}
	}
    elsif ( $self->test eq 'size' ) {
		$line .= $self->match_type;
	};
	

    my $header_list = ($self->header_list)?$self->header_list:'';
	my $key_list = ($self->key_list)?$self->key_list:'';

    $line.=' '.$header_list.' '.$key_list;

    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    $line =~ s/ +/ /g;
    # restore ", " in [ ]
    1 while ( $line =~ s/(\[[^\]]+?)" "/$1", "/);

    return $line;
}


=head1 NAME

Net::Sieve::Script::Condition - parse and write conditions in sieve scripts

=head1 SYNOPSIS

  use Net::Sieve::Script::Condition;

  my $cond = Net::Sieve::Script::Condition->new('header');
    $cond->match_type(':contains');
    $cond->key_list('"[Test4]"');
    $cond->header_list('"Subject"');

   print $cond->write();

or

   my $cond = Net::Sieve::Script::Condition->new(
     'anyof (
       header :contains "Subject" "[Test]",
	   header :contains "Subject" "[Test2]")'
	 );

   print $cond->write();

=head1 DESCRIPTION

Parse and write condition part of Sieve rules, see L<Net::Sieve::Script>.

Support RFC 5228, 5231 (relationnal) and regex draft

=head1 CONSTRUCTOR

=head2 new

Match and set accessors for each condition object in conditions tree, "test" is mandatory 

Internal

  id :        id for condition, set by creation order
  condition : array of sub conditions 
  parent :    parent of sub condition
  AllConds :  array of pointers for all conditions

Condition parts
  not          : 'not' or nothing
  test         : 'header', 'address', 'exists', ...
  key_list     : "subject" or ["To", "Cc"]
  header_list  : "text" or ["text1", "text2"]
  address_part : ':all ', ':localpart ', ...
  match_type   : ':is ', ':contains ', ...
  comparator   : string part

=head1 METHODS

=head2 equals

 Purpose  : test conditions
 Return   : 1 on equals conditions

=head2 write

 Purpose  : write rule conditions in text format
 Return   : multi-line formated text

=head1 AUTHOR

    Yves Agostini
    CPAN ID: YVESAGO
    Univ Metz
    agostini@univ-metz.fr
    http://www.crium.univ-metz.fr

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

return 1;
