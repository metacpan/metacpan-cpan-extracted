package Net::Sieve::Script;
use strict;
use warnings;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.08';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw(_strip);
    @EXPORT_OK   = qw(_strip);
    %EXPORT_TAGS = ();
}

use base qw(Class::Accessor::Fast);
use Net::Sieve::Script::Rule;

=head1 NAME

Net::Sieve::Script - Parse and write sieve scripts

=head1 SYNOPSIS

  use Net::Sieve::Script;

  my $test_script = 'require "fileinto";
     # Place all these in the "Test" folder
     if header :contains "Subject" "[Test]" {
	       fileinto "Test";
     }';

  my $script = Net::Sieve::Script->new ($test_script);

     print "OK" if ( $script->parsing_ok ) ;

     print $script->write_script;

or

    my $script = Net::Sieve::Script->new();

    my $cond = Net::Sieve::Script::Condition->new('header');
       $cond->match_type(':contains');
       $cond->header_list('"Subject"');
       $cond->key_list('"Re: Test2"');

    my $actions = 'fileinto "INBOX.test"; stop;';

    my $rule =  Net::Sieve::Script::Rule->new();
       $rule->add_condition($cond);
       $rule->add_action($actions);

       $script->add_rule($rule);

       print $script->write_script;



=head1 DESCRIPTION

Manage sieve script

Read and parse file script, make L<Net::Sieve::Script::Rule>, L<Net::Sieve::Script::Action>, L<Net::Sieve::Script::Condition> objects

Write sieve script

Support RFC 5228 - sieve base
    RFC 5231 - relationnal
    RFC 5230 - vacation
    Draft regex

missing 
    5229 variables
    5232 imapflags
    5233 subaddress
    5235 spamtest
    notify draft

=cut

__PACKAGE__->mk_accessors(qw(raw rules require max_priority));

=head1 CONSTRUCTOR

=head2 new

    Argument : optional text script
    Purpose  : if param, put script in raw, parse script
    Return   : main Script object

Accessors :

    ->raw()          : read or set original text script
    ->require()      : require part of script
    ->rules()        : array of rules
    ->max_priority() : last rule id 

=cut

sub new
{
    my ($class, $param) = @_;

    my $self = bless ({}, ref ($class) || $class);
    my @LISTS = qw((\[.*?\]|".*?"));

    if ($param) {
        $self->raw($param); 
        $self->require($1) if ( $param =~ m/require @LISTS;/si );
        $self->read_rules();
    }

    # break if more than 50 rules
    die "50 rules does not sound reasonable !" 
            if  (  $self->max_priority() && $self->max_priority() >= 50 );

    return $self;
}

=head1 METHODS

=head2 parsing_ok

return 1 on raw parsing success

=cut

sub parsing_ok
{
    my $self = shift;

    return ( $self->_strip eq _strip($self->write_script) );
}

=head2 write_script

Purpose : write full script, require and rules parts

Return  : set current require,
         return rules ordered by priority in text format

=cut

sub write_script {
    my $self = shift;
    my $text;
	my %require = ();

    foreach my $rule ( sort { $a->priority() <=> $b->priority() } @{$self->rules()} ) {
      $text .= $rule->write."\n";
	  foreach my $req ($rule->require()) {
	      $require{$req->[0]} = 1 if defined $req->[0];
	  }
    }

#TODO keep original require if current is include, for test parsing
    my $require_line;
    my $count;
    foreach my $req (sort keys %require) {
	    next if(!$req);
	    $require_line .= ', "'.$req.'"';
	    $count++;
    };
    $require_line =~ s/^, //;
    $require_line = '['.$require_line.']' if ($count > 1);

	$self->require($require_line);

    $require_line = "require $require_line;\n" if $require_line;

    return $require_line.$text;
}

=head2 equals

 $object->equals($test_object): return 1 if $object and $test_object are equals

=cut

sub equals {
    my $self = shift;
    my $object = shift;

    return 0 unless (defined $object);
    return 0 unless ($object->isa('Net::Sieve::Script'));

    my @accessors = qw( require );

    foreach my $accessor ( @accessors ) {
        my $myvalue = $self->$accessor;
        my $theirvalue = $object->$accessor;
        if (defined $myvalue) {
            return 0 unless (defined $theirvalue); 
            return 0 unless ($myvalue eq $theirvalue);
        } else {
            return 0 if (defined $theirvalue);
        }
    }

    if (defined $self->rules) {
        my @myrules = sort { $a->priority() <=> $b->priority() } @{$self->rules()};
        my @theirrules = sort { $a->priority() <=> $b->priority() } @{$object->rules()} ;
        return 0 unless ($#myrules == $#theirrules);

        unless ($#myrules == -1) {
            foreach my $index (0..$#myrules) {
                my $myrule = $myrules[$index];
                my $theirrule = $theirrules[$index];
                if (defined ($myrule)) {
					return 0 unless ($myrule->isa(
									'Net::Sieve::Script::Rule'));
                    return 0 unless ($myrule->equals($theirrule));
                } else {
                    return 0 if (defined ($theirrule));
                }
            }
        }

    } else {
        return 0 if (defined ($object->rules));
    }
	return 1;
}


=head2 read_rules

 $script->read_rules()  : read rules from raw 
 $script->read_rules($some_text) : parse text rules
 use of read_rules set $script->rules()

Return 1 on success

=cut

sub read_rules
{
    my $self = shift;
    my $text_rules = shift || $self->raw();

    my @LISTS = qw((\[.*?\]|".*?"));
    
    $self->require($1) if ( $text_rules =~ m/require @LISTS;/si );

    #read rules from raw or from $text_rules if set
    my $script_raw = $self->_strip($text_rules);

    my @Rules;

    # for simple vacation RFC 5230
    if ($script_raw =~m/^(vacation .*)$/) {
        push @Rules, Net::Sieve::Script::Rule->new(ctrl => 'vacation',block => $1,order =>1)
    }

    my $order;
    while ($script_raw =~m/(if|else|elsif) (.*?){(.*?)}([\s;]?)/isg) {
        my $ctrl = lc($1);
        my $test_list = $2;
        my $block = $3;

        ++$order;

        # break if more than 50 rules
        die "50 rules does not sound reasonable !" 
             if  ( $order >= 50 );

        my $pRule = Net::Sieve::Script::Rule->new (
            ctrl => $ctrl,
            test_list => $test_list,
            block => $block,
            order => $order
            );

        push @Rules, $pRule;
    };

    $self->rules(\@Rules);
	$self->max_priority($order);

    return 1;
}

=head2 find_rule

Return L<Net::Sieve::Script::Rule> pointer find by priority

Return 0 on error, 1 on not find

=cut

sub find_rule
{
    my $self = shift;
    my $priority = shift;
    return 0 if $priority > $self->max_priority || $priority <= 0;
    return 0 if not  defined $self->rules;

    foreach my $rule (@{$self->rules}) {
        return $rule if ($rule->priority == $priority );
    }

    return 1;
}

=head2 swap_rules

Swap priorities, 
 now don't take care of if/else/elsif

Return 1 on success, 0 on error

=cut

sub swap_rules
{
    my $self = shift;
    my $swap1 = shift;
    my $swap2 = shift;

    return 0 if $swap1 == $swap2;

    my $pr1 = $self->find_rule($swap1);
    my $pr2 = $self->find_rule($swap2);
    
    return 0 if ref($pr1) ne 'Net::Sieve::Script::Rule';
    return 0 if ref($pr2) ne 'Net::Sieve::Script::Rule';

    my $mem_pr2 = $pr2->priority();
    $pr2->priority($pr1->priority());
    $pr1->priority($mem_pr2);

    return 1;
}

=head2 reorder_rules

Reorder rules with a list of number, start with 1, and with blanck separator. Usefull for ajax sort functions.

Thank you jeanne for your help in brain storming.

Return 1 on success, 0 on error

=cut

sub reorder_rules
{
    my $self = shift;
    my $list = shift;

	return 0 if ( ! $list );

    my @swap = split ' ',$list;

	return 0 if ( ! scalar @swap );
	return 0 if ( scalar @swap != $self->max_priority );

    my @new_ordered_rules;
    foreach my $swap ( @swap ) {
      if ($swap =~ m/\d+/) {
       my $rule = $self->find_rule($swap);
       push @new_ordered_rules, $rule;
      }
    }

    my $i=1;
    foreach my $rule (@new_ordered_rules) {
      $rule->priority($i);
      $i++;
    };

    return 1;
}

=head2 delete_rule

Delete rule and change priority, delete rule take care for 'if' test

 if deleted is 'if'
  delete next if next is 'else'
  change next in 'if' next is 'elsif'

Return : 1 on success, 0 on error

=cut

sub delete_rule
{
    my $self = shift;
    my $id = shift;
    my $deleted = 0;
    my @Rules =  defined $self->rules?@{$self->rules}:();
    my @NewRules = ();
    my $order = 0;
    
    for ( my $i = 0; $i < scalar(@Rules); $i++ ) {
        my $rule = $Rules[$i];
        my $next=$i+1;
        if ($rule->priority == $id) {
            $deleted = 1;
            if ( defined $Rules[$next] && $rule->alternate eq 'if') {
                $Rules[$next]->alternate('if') 
                    if ($Rules[$next]->alternate eq 'elsif' );

                if ($Rules[$next]->alternate eq 'else' ) {
                    $i++;
                    $rule = $Rules[$i];
                }
            }
        }
        else {
            ++$order;
            $rule->priority($order);
            push @NewRules, $rule;
        }
    }

    $self->max_priority($order);
    $self->rules(\@NewRules);
    
    return $deleted;
}

=head2 add_rule

Purpose  : add a rule in end of script

Return   : priority on success, 0 on error

Argument : Net::Sieve::Script::Rule object

=cut

sub add_rule
{
    my $self = shift;
    my $rule = shift;

    return 0 if ref($rule) ne 'Net::Sieve::Script::Rule';

    my $order = $self->max_priority();
    my @Rules =  defined $self->rules?@{$self->rules}:();

    ++$order;
    $rule->priority($order);
    push @Rules, $rule;

    $self->max_priority($order);
    $self->rules(\@Rules);

    return $order;
}

# private and exported tool _strip
#  strip a string or strip raw
#  return a string
# usefull for parsing or tests
#
# default remove require line or set $keep_require

sub _strip {
    my ( $self, $script_raw, $keep_require ) = @_;

    if ( ref($self) eq 'Net::Sieve::Script' ) {
        $script_raw = $self->raw() if (! $script_raw );
    } else {
        $script_raw = $self;
    }

    $script_raw =~ s/\#.*//g;      # hash-comment
    $script_raw =~ s!/\*.*.\*/!!g; # bracket-comment
    $script_raw =~ s/\t/ /g;  # remove tabs 
    $script_raw =~ s/\(/ \( /g; #  add white-space around ( 
    $script_raw =~ s/\)/ \) /g; #  add white-space around )
    #$script_raw =~ s/\s+\[/ \[ /g; # add white-space around [ 
    #$script_raw =~ s/\]\s+/ \] /g; # add white-space around ]
    $script_raw =~ s/\]\s*,/\],/g; # add white-space around ]
    $script_raw =~ s/"\s*,/", /g; # add white-space after , in list
    $script_raw =~ s/"\s+;/";/g; # remove white-space between " and ;
    $script_raw =~ s/\s+/ /g; # remove doubs white-space
    $script_raw =~ s/^\s+//; # trim
    $script_raw =~ s/\s+$//; #trim

    $script_raw =~ s/require.*?["\]];\s+//sgi if (!$keep_require); #remove require

	return $script_raw;
}

=head1 BUGS

Rewrite a hand made script will lose comments. Verify parsing success with parsing_ok method before write a new script.

=head1 SUPPORT

Please report any bugs or feature requests to "bug-net-sieve-script at rt.cpan.org", or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Sieve-Script>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 AUTHOR

Yves Agostini - Univ Metz - <agostini@univ-metz.fr>

L<http://www.crium.univ-metz.fr>

=head1 COPYRIGHT

Copyright 2008 Yves Agostini - <agostini@univ-metz.fr>

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Net::Sieve>

=cut

1;
# The preceding line will help the module return a true value

