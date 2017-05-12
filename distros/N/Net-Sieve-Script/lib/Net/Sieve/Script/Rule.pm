package Net::Sieve::Script::Rule;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use vars qw($VERSION);

$VERSION = '0.08';

use  Net::Sieve::Script::Action;
use Net::Sieve::Script::Condition;

=head1 NAME

Net::Sieve::Script::Rule - parse and write rules in sieve scripts

=head1 SYNOPSIS

  use Net::Sieve::Script::Rule;
        my $pRule = Net::Sieve::Script::Rule->new (
            ctrl => $ctrl,
            test_list => $test_list,
            block => $block,
            order => $order
            );

or
    my $rule =  Net::Sieve::Script::Rule->new();
    my $cond = Net::Sieve::Script::Condition->new('header');
       $cond->match_type(':contains');
       $cond->header_list('"Subject"');
       $cond->key_list('"Re: Test2"');
    my $actions = 'fileinto "INBOX.test"; stop;';

      $rule->add_condition($cond);
      $rule->add_action($actions);

      print $rule->write;

=head1 DESCRIPTION



=cut

__PACKAGE__->mk_accessors(qw(alternate conditions actions priority require));

=head1 CONSTRUCTOR

=head2 new

    Arguments :
        order =>     : optionnal set priority for rule
        ctrl  =>     : optionnal default 'if', else could be 'else', 'elsif' 
                       or 'vacation'
        test_list => : optionnal conditions by string or by Condition Object
        block =>     : optionnal block of commands
    Returns   :   Net::Sieve::Script::Rule object

Set accessors

  alternate  : as param ctrl
  conditions : first condition in tree
  actions    : array of actions objects
  priority   : rule order in script, main id for rule
  require    :


=cut

sub new
{
    my ($class, %param) = @_;

    my $self = bless ({}, ref ($class) || $class);

    $self->alternate(lc($param{ctrl})||'if');
    $self->priority($param{order}) if $param{order};

    if ($param{block}) {
        my @Actions;
        my @commands = split( ';' , $param{block});
        foreach my $command (@commands) {
            push @Actions, Net::Sieve::Script::Action->new($command);
        };  
        $self->actions(\@Actions);
    }

    if ($param{test_list}) {
        my $cond = ( ref($param{test_list}) eq 'Net::Sieve::Script::Condition' ) ? 
            $param{test_list} :
            Net::Sieve::Script::Condition->new($param{test_list});
        $self->conditions($cond);
    }


    return $self;
}

=head1 METHODS

=head2 equals

return 1 if rules are equals

=cut

sub equals {
    my $self = shift;
    my $object = shift;

    return 0 unless (defined $object);
    return 0 unless ($object->isa('Net::Sieve::Script::Rule'));

    # Should we test "id" ? Probably not it's internal to the
    # representaion of this object, and not a part of what actually makes
    # it a sieve "condition"

    #my @accessors = qw( alternate require );
    my @accessors = qw( alternate );

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

	if ( defined $self->conditions ) {
		return 0 unless ($self->conditions->isa(
							'Net::Sieve::Script::Condition'));
		return 0 unless ($self->conditions->equals($object->conditions));
	} else {
		return 0 if (defined $object->conditions ) ;
	}

	if (defined $self->actions) {
		my $tmp = $self->actions;
		my @myactions = @$tmp;
		$tmp = $object->actions;
		my @theiractions = @$tmp;
		return 0 unless ($#myactions == $#theiractions);

		unless ($#myactions == -1) {
			foreach my $index (0..$#myactions) {
				my $myaction = $myactions[$index];
				my $theiraction = $theiractions[$index];
				if (defined ($myaction)) {
					 return 0 unless ($myaction->isa(
					 		'Net::Sieve::Script::Action'));
					return 0 unless ($myaction->equals($theiraction));
				} else {
					return 0 if (defined ($theiraction));
				}       
			}       
		}       

	} else {
		return 0 if (defined ($object->actions));
	}

	return 1;
}

=head2 write

 Return rule in text format

=cut

sub write
{
    my $self = shift;

    # for simple vacation RFC 5230
    if ( $self->alternate eq 'vacation' ) {
        return $self->write_action;
    }

    my $write_condition = ($self->write_condition)?$self->write_condition:'';
	my $write_action = ($self->write_action)?$self->write_action:'';

	return $self->alternate.' '.
            $write_condition."\n".
            '    {'.
            "\n".$write_action.
            '    } ';
}

=head2 write_condition

 set require for used conditions
 return conditions in text format

=cut

sub write_condition
{
    my $self = shift;

    return undef if ! $self->conditions;

	if ( defined $self->conditions->require )  {
      my $require = $self->require();
	  push @{$require}, @{$self->conditions->require};
	  $self->require($require);
	};

    return $self->conditions->write();
}

=head2 write_action

 set require for used actions
 return actions in text format

=cut

sub write_action
{
    my $self = shift;

    my $actions = '';
    my $require = $self->require();

    foreach my $command ( @{$self->actions()} ) {
            next if (! $command->command);
            $actions .= '    '.$command->command;
            $actions .= ' '.$command->param if ($command->param);
			$actions .= ";\n";
			push (@{$require}, $command->command) if (
              $command->command ne 'keep' &&
              $command->command ne 'discard' &&
#              $command->command ne 'reject' &&
              $command->command ne 'stop' ); # rfc 3528 4.) implementation MUST support 
    }
	$self->require($require);
    return $actions;
}

=head2 delete_condition

 Purpose   : delete condition by rule, delete all block on delete anyof/allof
             delete single anyof/allof block : single condition move up
 Arguments : condition id
 Returns   : 1 on success, 0 on error

=cut

sub delete_condition
{
    my $self = shift;
    my $id = shift;

    my $cond_to_delete =  $self->conditions->AllConds->{$id};
    return 0 if (! defined $cond_to_delete);

    delete $self->conditions->AllConds->{$id};

    if (! defined $cond_to_delete->parent) {
        $self->conditions(undef);
        return 1;
    }
    my @parent_conditions = @{$cond_to_delete->parent->condition()};
    my @new_conditions = ();
    foreach my $cond (@parent_conditions) {
        push @new_conditions, $cond if ( $cond->id != $id );
    }

    # remove single block
    if ( scalar @new_conditions == 1 ) {
        my $last_cond = $new_conditions[0];
        my $parent = $last_cond->parent;
        my $old_parent = $parent->parent;
        my $new_cond = Net::Sieve::Script::Condition->new($last_cond->write);
           $self->delete_condition($parent->id);
           $self->add_condition($new_cond,(defined $old_parent)?$old_parent->id:0);
    }

    $cond_to_delete->parent->condition(\@new_conditions);
    return 1;
}

=head2 add_condition

 Purpose   : add condition to rule, add 'allof' group on second rule
 Arguments : string or Condition object
 Returns   : new condition id or 0 on error

=cut

sub add_condition
{
    my $self = shift;
    my $cond = shift;
    my $parent_id = shift;
    $cond = ref($cond) eq 'Net::Sieve::Script::Condition' ? $cond : Net::Sieve::Script::Condition->new($cond);

    if ($parent_id) {
        # add new condition to anyof/allof parent block
        my $parent = $self->conditions->AllConds->{$parent_id};
        return 0 if (!$parent || ( $parent->test ne 'allof' && $parent->test ne 'anyof') );
        my @conditions_list = (defined $parent->condition())?@{$parent->condition()}:();
        $cond->parent($parent);
        push @conditions_list, $cond;
        $parent->condition(\@conditions_list);
        return 1;
    }

    if ( defined $self->conditions() ) {
        if ( $self->conditions->test eq 'anyof' 
               || $self->conditions->test eq 'allof' ) {
            # add condition on first block
            my @conditions_list = @{$self->conditions->condition()};
            $cond->parent($self->conditions);
            push @conditions_list, $cond;
            $self->conditions->condition(\@conditions_list);
        }
        else {
            # add a new block on second add
            my $new_anyoff = Net::Sieve::Script::Condition->new('allof');
            my @conditions_list = ();
            $cond->parent($new_anyoff);
            $self->conditions->parent($new_anyoff);
            push @conditions_list, $self->conditions;
            push @conditions_list, $cond;
            $new_anyoff->condition(\@conditions_list);
            $self->conditions($new_anyoff);
        }
    } 
    else {
        # add first condition
        $self->conditions($cond);
    }

    return $cond->id;
}

=head2 swap_actions

 swap actions by order
 return 1 on succes, 0 on failure

=cut

sub swap_actions
{
    my $self = shift;
    my $swap1 = shift;
    my $swap2 = shift;

    return 0 if $swap1 == $swap2;
    return 0 if (! defined $self->actions);
    return 0 if $swap1 <= 0 || $swap2 <= 0;

    my $pa1 = $self->find_action($swap1);
    my $pa2 = $self->find_action($swap2);

    return 0 if ref($pa1) ne 'Net::Sieve::Script::Action';
    return 0 if ref($pa2) ne 'Net::Sieve::Script::Action';

    my @Actions = @{$self->actions()};
    my @NewActions = ();

    my $i = 1 ;
    foreach my $action (@{$self->actions()}) {
        if ($i == $swap1 ) {
            push @NewActions, $pa2;
        }
        elsif ($i == $swap2 ) {
            push @NewActions, $pa1;
        }
        else {
            push @NewActions, $action;
        };  
        $i++;
    }
    $self->actions(\@NewActions);

    return 1;
}

=head2 find_action

 find action by order
 Returns:  Net::Sieve::Script::Action object, 0 on error

=cut

sub find_action
{
    my $self = shift;
    my $order = shift;

    return 0 if (! defined $self->actions);
    my @Actions = @{$self->actions()};
    my $i = 1;
    foreach my $action (@Actions) {
        return $action if ($i == $order);
        $i++;
    }

    return 0;
}

=head2 delete_action

delete action by order, first is 1;

=cut

sub delete_action
{
    my $self = shift;
    my $order = shift;
    my $deleted = 0;
    my @NewActions;

    return 0 if (! defined $self->actions);
    my @Actions = @{$self->actions()};

    my $i = 1;
    foreach my $action (@Actions) {
        if ($i == $order) {
            $deleted = 1;
        }
        else {
            push @NewActions, $action;
            };
        $i++;
    };

    $self->actions(\@NewActions);

    return $deleted;
}

=head2 add_action

 Purpose   : add action at end of block
 Arguments : command line  
             or command line list with ; separator
             or Net::Sieve::Script::Action object
 Return    : 1 on success

=cut

sub add_action
{
    my $self = shift;
    my $action = shift;

    my @Actions = defined $self->actions?@{$self->actions()}:();

    if ($action =~m /;/g && ref($action) ne 'Net::Sieve::Script::Action' ) {
        my @list_actions = split(';',$action);
        foreach my $sub_action (@list_actions) {
            push @Actions, Net::Sieve::Script::Action->new($sub_action);
        }
    } else {

        my $pAction = (ref($action) eq 'Net::Sieve::Script::Action')?$action:Net::Sieve::Script::Action->new($action);

        push @Actions, $pAction;
    }

    $self->actions(\@Actions);

    return 1;
}


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

