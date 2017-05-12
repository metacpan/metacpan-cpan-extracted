package Solstice::State::Machine;

=head1 NAME

Solstice::State::Machine - Representation of a finite state machine for Solstice.  See Solstice::State::Tracker to run through a state machine.

=head1 SYNOPSIS

use Solstice::State::Machine;

my $machine = new Solstice::State::Machine();

=head1 DESCRIPTION

This is the main state machine representation for the Solstice tools.
The Solstice::State::Tracker uses this representation to keep track of
state.  A Solstice::State::Machine's data is stored only once in the
main apache thread via Solstice::Service::Memory;

=cut


use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);

use Solstice::State::Node;
use Solstice::State::Transition;
use Solstice::State::FlowTransition;
use Solstice::State::PageFlow;
use Solstice::State::Memory;
use Solstice::NamespaceService;

use XML::LibXML;

use constant XML_APPLICATION                                  => 'application';
use constant XML_STATES                                       => 'states';
use constant XML_STATE                                        => 'state';
use constant XML_STATE_ATTR_NAME                              => 'name';
use constant XML_STATE_ATTR_CONTROLLER                        => 'controller';
use constant XML_PAGEFLOWS                                    => 'pageflows';
use constant XML_PAGEFLOW                                     => 'pageflow';
use constant XML_PAGEFLOW_ATTR_NAME                           => 'name';
use constant XML_PAGEFLOW_ATTR_ENTRANCE                       => 'entrance';
use constant XML_PAGEFLOW_STATE                               => 'state';
use constant XML_PAGEFLOW_STATE_ATTR_NAME                     => 'name';
use constant XML_PAGEFLOW_STATE_TRANSITIONS                   => 'transitions';
use constant XML_PAGEFLOW_STATE_TRANSITION                    => 'transition';
use constant XML_PAGEFLOW_STATE_TRANSITION_ATTR_ACTION        => 'action';
use constant XML_PAGEFLOW_STATE_TRANSITION_ATTR_STATE         => 'state';
use constant XML_PAGEFLOW_STATE_TRANSITION_ATTR_ONBACK        => 'onback';
use constant XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE          => 'lifecycle';
use constant XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME=> 'name';
use constant XML_PAGEFLOW_STATE_BEGIN                         => 'begin';
use constant XML_PAGEFLOW_STATE_BEGIN_ATTR_ACTION             => 'action';
use constant XML_PAGEFLOW_STATE_BEGIN_ATTR_APPLICATION        => 'application';
use constant XML_PAGEFLOW_STATE_BEGIN_ATTR_PAGEFLOW           => 'pageflow';
use constant XML_PAGEFLOW_STATE_BEGIN_ATTR_ONBACK             => 'onback';
use constant XML_PAGEFLOW_STATE_FAILOVERS                     => 'failovers';
use constant XML_PAGEFLOW_STATE_FAILOVER                      => 'failover';
use constant XML_PAGEFLOW_STATE_FAILOVER_ATTR_NAME            => 'name';
use constant XML_PAGEFLOW_STATE_FAILOVER_ATTR_STATE           => 'state';
use constant GLOBAL_TRANSITIONS                                  => 'globaltransitions';

use constant TRUE => 1;
use constant FALSE => 0;

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut



=item new()

Creates a new Solstice::State::Machine object.

returns - a new state machine object.

=cut

sub new {
    my ($classname) = @_;

    my $config = new Solstice::Configure();
    my $memory = new Solstice::State::Memory();

    if ($config->getDevelopmentMode()) {
        # load the pageflow files again if they've been modified note:
        # we need to reload all of them if one of them has changed
        my $pageflow_files = $config->getStateFiles();
        my $requires_parsing = FALSE;
        foreach my $app_namespace (keys %$pageflow_files) {
            if ($memory->requiresParsing($pageflow_files->{$app_namespace})) {
                $requires_parsing = TRUE;
            }
        }

        if ($requires_parsing) {
            Solstice::State::Machine->initialize($pageflow_files);
        }
    }

    my $self = $memory->getMachine();

    unless ($self) {
        die "Can't create a Solstice::State::Machine before initialize()\n";
    }

    return $self;
}


=item initialize()

Initializes the state machine using the XML files given.

$xmlFiles - a reference to a hash of XML filenames.

=cut

sub initialize {
    my ($classname, $xml_files) = @_;

    my $self = bless {}, $classname;

    foreach my $app_namespace (keys %$xml_files) {
        $self->{'_appNamespace'} = $app_namespace;
        $self->_loadStateFile($xml_files->{$app_namespace});
    }

    my $memory = new Solstice::State::Memory();
    $memory->setMachine($self);

    return TRUE;
}


=item _loadStateFile($xmlFile)

Builds the state graph from the XML file.

$xmlFile - the path to the xml file.

returns - whether successful.

=cut

sub _loadStateFile {
    my ($self, $xml_file) = @_;

    my $parsed_doc = $self->_parseXml($xml_file);

    unless ($self->_validateStateXML($parsed_doc)) {
        die "State file $xml_file failed validation: ".$self->{'_errstr'};
    }

    my $root_node = $parsed_doc->getDocumentElement();

    # load stuff from the xml nodes
    $self->_loadStates($root_node->getChildrenByTagName(XML_STATES)->item(0));
    $self->_loadGlobalTransitions($root_node->getChildrenByTagName(GLOBAL_TRANSITIONS)->item(0));
    $self->_loadPageFlows($root_node->getChildrenByTagName(XML_PAGEFLOWS)->item(0));

    # remember when we parsed this xml file
    my $memory = new Solstice::State::Memory();
    $memory->setLastParsedTime($xml_file, time);
}


=item _validateStateXML($xmlDoc)

=cut

sub _validateStateXML {
    my ($self, $xml_doc) = @_;

    my $config = Solstice::Configure->new();
   
    # This was commented out... if this starts to cause problems we might need to kill pageflow validation 
    # until we figure out why it is freaking out on server restart
    my $schema = XML::LibXML::Schema->new(
        location => $config->getRoot().'/conf/schemas/pageflow.xsd'
    );

    eval { $schema->validate($xml_doc) };
    if ($@) {
        $self->{'_errstr'} = $@;
        return 0;
    }
    return 1;
}


=item _fullyQualify($name, [$namespace])

Fully qualifies a state or flow name by prefixing it with the application
namespace.

=cut

sub _fullyQualify {
    my ($self, $name, $app_namespace) = @_;

    return $name if !defined $self->{_appNamespace};

    my $namespace = $app_namespace || $self->{_appNamespace};
    return $namespace . '::' . $name;
}


=item _loadStates($xmlNode)

Given the parsed XML node for the states section of the
Xml file, create and store the corresponding State objects.

$xmlNode - the XML node to load from.

=cut

sub _loadStates {
    my ($self, $xml_node) = @_;

    for my $state_node ($xml_node->getChildrenByTagName(XML_STATE)) {
        # read the useful info from the node
        my $state_name = $state_node->getAttribute(XML_STATE_ATTR_NAME);
        $state_name = $self->_fullyQualify($state_name);

        my $controller_class = $state_node->getAttribute(XML_STATE_ATTR_CONTROLLER);

        if ($self->_stateExists($state_name)) {
            die "State '$state_name' is defined more than once.\n";
        }

        $self->_addState($state_name, $controller_class);
    }
}


sub _loadGlobalTransitions {
    my ($self, $xml_node) = @_;
    
    return unless defined $xml_node;

    for my $transition ($xml_node->childNodes){
        my $pageflow_transition;
        if($transition->nodeName() eq XML_PAGEFLOW_STATE_TRANSITION){    
            $pageflow_transition = $self->_loadGlobalTransition($transition);
        }elsif ($transition->nodeName() eq XML_PAGEFLOW_STATE_BEGIN){
            $pageflow_transition = $self->_loadGlobalFlowTransition($transition);    
        }
        $self->_addGlobalTransition($pageflow_transition, $self->{'_appNamespace'}) if defined $pageflow_transition;

    }
}

sub _loadPageFlowGlobalTransitions {
    my ($self, $xml_node,$flow_name) = @_;

    return unless defined $xml_node;

    for my $transition ($xml_node->childNodes){
        my $pageflow_transition;
        if($transition->nodeName() eq XML_PAGEFLOW_STATE_TRANSITION){
            $pageflow_transition = $self->_loadGlobalTransition($transition);
        }elsif ($transition->nodeName() eq XML_PAGEFLOW_STATE_BEGIN){
            $pageflow_transition = $self->_loadGlobalFlowTransition($transition);
        }
        $self->_addPageFlowGlobalTransition($pageflow_transition, $self->{'_appNamespace'}, $flow_name) if defined $pageflow_transition;

    }
}

sub _loadGlobalFlowTransition {
    my ($self, $xml_node) = @_;

        # get the name of the action
    my $action = $xml_node->getAttribute(
      XML_PAGEFLOW_STATE_BEGIN_ATTR_ACTION);
    # get the application to transition to
    my $application = $xml_node->getAttribute(
      XML_PAGEFLOW_STATE_BEGIN_ATTR_APPLICATION) || $self->{_appNamespace};
    # get the name of the page flow to include
    my $name = $xml_node->getAttribute(
      XML_PAGEFLOW_STATE_BEGIN_ATTR_PAGEFLOW);
    # record whether the user can back over the transition
    my $on_back = $xml_node->getAttribute(
      XML_PAGEFLOW_STATE_BEGIN_ATTR_ONBACK);

      # read the lifecycle processes
    my %lifecycle_stages = ();

    for my $lifecycleNode ($xml_node->getChildrenByTagName(
        XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE)) {
        my $stage = $lifecycleNode->getAttribute(
          XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME);
        $lifecycle_stages{$stage} = 1;
    }

    # add the transition to the flow
    my $transition = $self->_createFlowTransition($action,
                                                  $application,
                                                  $application.'::'.$name,
                                                  $on_back,
                                                  \%lifecycle_stages);
    return $transition;
#    $self->_addGlobalTransition($transition, $self->{'_appNamespace'});

    
}

sub _loadGlobalTransition {
    my ($self, $transition) = @_;
    my $action = $transition->getAttribute(XML_PAGEFLOW_STATE_TRANSITION_ATTR_ACTION);
    # get the name of the target state
    my $transition_final = $transition->getAttribute(
        XML_PAGEFLOW_STATE_TRANSITION_ATTR_STATE);
    $transition_final = $self->_fullyQualify($transition_final);
    # record whether the user can back over this transition
    my $on_back = $transition->getAttribute(
        XML_PAGEFLOW_STATE_TRANSITION_ATTR_ONBACK);

    my $pageflow_destination = $transition->getAttribute(XML_PAGEFLOW);
    # read the lifecycle processes
    my %lifecycle_stages = ();

    for my $lifecycleNode ($transition->getChildrenByTagName(
            XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE)) {

        my $stage = $lifecycleNode->getAttribute(
            XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME);
        $lifecycle_stages{$stage} = 1;
    }

    my $global_transition = $self->_createTransition($action,
        $transition_final,
        $on_back,
        $pageflow_destination,
        \%lifecycle_stages);
    return $global_transition;
    # $self->_addGlobalTransition($global_transition, $self->{'_appNamespace'});
}
=item _loadPageFlows($xmlNode)

Loads the page flows that this application exposes from the $xmlNode.

$xmlNode - the XML node to load from.

=cut

sub _loadPageFlows {
    my ($self, $xml_node) = @_;

    for my $pageflow_node ($xml_node->getChildrenByTagName(XML_PAGEFLOW)) {
        my $pageflow_name = $pageflow_node->getAttribute(
            XML_PAGEFLOW_ATTR_NAME);
        $pageflow_name = $self->_fullyQualify($pageflow_name);
        my $entrance = $pageflow_node->getAttribute(
            XML_PAGEFLOW_ATTR_ENTRANCE);
        $entrance = $self->_fullyQualify($entrance);

        # Construct the State::PageFlow object
        my $pageflow = $self->_createPageFlow($self->{_appNamespace},
                                              $pageflow_name,
                                              $entrance);
        $self->_loadPageFlowGlobalTransitions($pageflow_node->getChildrenByTagName(GLOBAL_TRANSITIONS)->item(0),$pageflow_name);

        # read in the rest of the info from xml
        for my $state_node ($pageflow_node->getChildrenByTagName(XML_PAGEFLOW_STATE)) {
            my $start_state = $state_node->getAttribute(
                XML_PAGEFLOW_STATE_ATTR_NAME);
            $start_state = $self->_fullyQualify($start_state);

            if (not $self->_stateExists($start_state)) {
                die "Pageflow transition start state " .
                  "'$start_state' does not exist\n";
            }

            for my $childNode ($state_node->childNodes()) {
                if ($childNode->nodeName() eq
                    XML_PAGEFLOW_STATE_TRANSITIONS) {

                    # load the transitions (and pageflows via 'begins')
                    for my $transitionNode ($childNode->childNodes()) {
                        if ($transitionNode->nodeName() eq
                            XML_PAGEFLOW_STATE_TRANSITION) {

                            # load a transition
                            $self->_loadTransition($pageflow,
                                                   $start_state,
                                                   $transitionNode);

                        } elsif ($transitionNode->nodeName() eq
                                 XML_PAGEFLOW_STATE_BEGIN) {

                            # load a pageflow include
                            $self->_loadPageFlowInclude($pageflow,
                                                        $start_state,
                                                        $transitionNode);
                        }
                    }
                } elsif ($childNode->nodeName() eq
                         XML_PAGEFLOW_STATE_FAILOVERS) {

                    # load failovers
                    $self->_loadFailovers($pageflow,
                                          $start_state,
                                          $childNode);
                }
            }
        }

        # Register for retreival by other applications that include it
        $self->_addPageFlow($pageflow);
    }
}


=item _loadTransition($pageflow, $transition_start, $xmlNode)

Loads a single transition from the $xmlNode.

$pageflow - the page flow to add the transition to.
$transition_start - the start state of the transition.
$xmlNode - the XML to load from.

=cut

sub _loadTransition {
    my ($self, $pageflow, $transition_start, $xml_node) = @_;

    # get the name of the action
    my $action = $xml_node->getAttribute(
      XML_PAGEFLOW_STATE_TRANSITION_ATTR_ACTION);
    # get the name of the target state
    my $transition_final = $xml_node->getAttribute(
      XML_PAGEFLOW_STATE_TRANSITION_ATTR_STATE);
    $transition_final = $self->_fullyQualify($transition_final);
    # record whether the user can back over this transition
    my $on_back = $xml_node->getAttribute(
      XML_PAGEFLOW_STATE_TRANSITION_ATTR_ONBACK);

    die "State $transition_final is used as a destination but not defined.\n" unless
      $self->_stateExists($transition_final);

    # read the lifecycle processes
    my %lifecycle_stages = ();

    for my $lifecycleNode ($xml_node->getChildrenByTagName(
        XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE)) {

        my $stage = $lifecycleNode->getAttribute(
          XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME);
        $lifecycle_stages{$stage} = 1;
    }

    # add the transition to the current flow
    my $transition = $self->_createTransition($action,
                                              $transition_final,
                                              $on_back,
                                              undef,
                                              \%lifecycle_stages);

    $pageflow->addTransition($transition_start, $transition);
}


=item _loadPageFlowInclude($pageflow, $transition_start, $xmlNode)

Loads a page flow include and adds it to the $pageflow

$pageflow - the page flow to include the page flow include into.
$transition_start - the start state of the transition that takes you to
the new flow.
$xmlNode - the XML node to load from.

=cut

sub _loadPageFlowInclude {
    my ($self, $pageflow, $start_state, $xml_node) = @_;

    # get the name of the action
    my $action = $xml_node->getAttribute(
      XML_PAGEFLOW_STATE_BEGIN_ATTR_ACTION);
    # get the application to transition to
    my $application = $xml_node->getAttribute(
      XML_PAGEFLOW_STATE_BEGIN_ATTR_APPLICATION) || $self->{_appNamespace};
    # get the name of the page flow to include
    my $name = $xml_node->getAttribute(
      XML_PAGEFLOW_STATE_BEGIN_ATTR_PAGEFLOW);
    # record whether the user can back over the transition
    my $on_back = $xml_node->getAttribute(
      XML_PAGEFLOW_STATE_BEGIN_ATTR_ONBACK);

    # read the lifecycle processes
    my %lifecycle_stages = ();

    for my $lifecycleNode ($xml_node->getChildrenByTagName(
        XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE)) {
        my $stage = $lifecycleNode->getAttribute(
          XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME);
        $lifecycle_stages{$stage} = 1;
    }

    # add the transition to the flow
    my $transition = $self->_createFlowTransition($action,
                                                  $application,
                                                  $application.'::'.$name,
                                                  $on_back,
                                                  \%lifecycle_stages);

    $pageflow->addTransition($start_state, $transition);
}


=item _loadFailovers($state, $xmlNode)

Loads the failovers for a given state out of the Xml node.

$pageflow - the pageflow object to put the failovers in.
$state - the name of the state to load the failovers for.
$xmlNode - the Xml node to load from.

=cut

sub _loadFailovers {
    my ($self, $pageflow, $state, $xml_node) = @_;

    for my $failoverNode ($xml_node->getChildrenByTagName(
        XML_PAGEFLOW_STATE_FAILOVER)) {
        my $name = $failoverNode->getAttribute(XML_PAGEFLOW_STATE_FAILOVER_ATTR_NAME);
        my $failover_state = $failoverNode->getAttribute(XML_PAGEFLOW_STATE_FAILOVER_ATTR_STATE);
        $failover_state = $self->_fullyQualify($failover_state);

        $pageflow->addFailover($state, $name, $failover_state);
    }
}


=item _stateExists($stateName)

$stateName - the name of the state.

returns - whether the state exists in the machine.

=cut

sub _stateExists {
    my ($self, $state_name) = @_;

    return $self->{'_states'}->{$state_name} ||
      $state_name =~ m/.*__exit__$/;
}


=item _addState($stateName, $controller)

Adds a state to the machine.

$stateName - the name of the state to add.
$controller - the controller for the state.

=cut

sub _addState {
    my ($self, $state_name, $controller) = @_;

    $self->{'_states'}->{$state_name} =
      $self->_createNode($state_name, $controller);
}


=item _getState($stateName)

Gets the Solstice::State::Node object by name.

$stateName - the name of the state to return.

returns - the state with the given $stateName.

=cut

sub _getState {
    my ($self, $state_name) = @_;

    return $self->{'_states'}->{$state_name};
}


=item _addPageFlow($pageflow)

Adds a page flow to the machine.

=cut

sub _addPageFlow {
    my ($self, $pageflow) = @_;

    $self->{'_flows'}->{$pageflow->getName()} = $pageflow;
}

sub _addGlobalTransition {
    my ($self,$transition, $application) = @_;
    $self->{'_global_transitions'}{$application}{$transition->getName()} = $transition;
}

sub getGlobalTransition {
    my ($self, $name, $application) = @_;
    return $self->{'_global_transitions'}{$application}{$name};
}

sub _addPageFlowGlobalTransition {
    my ($self,$transition, $application, $flow_name) = @_;
    $self->{'_global_transitions'}{$application}{$flow_name}{$transition->getName()} = $transition;
}
sub getPageFlowGlobalTransition {
    my ($self, $name, $application, $flow_name) = @_;
    return $self->{'_global_transitions'}{$application}{$flow_name}{$name};
}

sub getGlobalTransitions {
    my $self = shift;
    return $self->{'_global_transitions'};
}

=item transition($flow, $state, $action)

Gets the target state given a page flow, an initial state, and a
transition action from it.

$flow - the page flow to use.
$state - the state name to transition from.
$action - the transition to take.

returns - ($do_pop, $new_flow, $new_state)

$do_pop - whether the transition exited a flow.
$new_flow - the new flow.
$new_state - the new state.

=cut

sub transition {
    my ($self, $flow, $state, $action) = @_;

    my $transition = $self->getPageFlow($flow)->getTransition($state, $action);
    
    # handle the transitions to a new page flow
    if (ref($transition) eq $self->_getFlowTransitionPackageName()) {
        my $new_flow = $self->getPageFlow($transition->getPageFlowName());
        return (0, $new_flow->getName(), $new_flow->getEntrance());
    }

    # handle regular transitions within a page flow (or exit transitions)
    my $new_state = $transition->getTargetState();
    my $do_pop = $new_state =~ m/.*::__exit__$/ ? 1 : 0;
    return ($do_pop, undef, $new_state);
}


=item getMainFlow($appNamespace)

Gets the main page flow for the machine.

=cut

sub getMainFlow {
    my ($self, $app_namespace) = @_;

    return $self->{'_flows'}->{$self->_fullyQualify('Main', $app_namespace)}->getName();
}


=item getStartState($appNamespace)

Gets the start state for an application.

=cut

sub getStartState {
    my ($self, $app_namespace) = @_;

    return $self->getPageFlow($self->getMainFlow($app_namespace))->getEntrance();
}


=item getPageFlow($pageflow_name)

Gets the page flow given the app namespace and its name.

=cut

sub getPageFlow {
    my ($self, $pageflow_name) = @_;
    return $self->{'_flows'}->{$pageflow_name};
}


=item getPageFlows()

Gets a reference to a hash of all the page flows.

=cut

sub getPageFlows {
    my ($self) = @_;
    return $self->{'_flows'};
}


=item _parseXml()

Parses the XML file.

returns - the parsed xml document.

=cut

sub _parseXml {
    my ($self, $xml_file) = @_;

    my $parser = XML::LibXML->new();
    
    my $xml_doc;
    eval { $xml_doc = $parser->parse_file($xml_file) };
    die "State file $xml_file could not be parsed:\n$@\n" if $@;
    
    return $xml_doc;
}


=item canUseBackButton($flow, $state, $transition)

Returns whether the user should be able to use the back button after
this transition.

=cut

sub canUseBackButton {
    my ($self, $flow, $state, $action) = @_;
    return not $self->getBackErrorMessage($flow, $state, $action);
}


=item getBackErrorMessage($flow, $state, $transition)

Returns the error message if a the back button is used and it is not allowed.

=cut

sub getBackErrorMessage {
    my ($self, $flow, $state, $action) = @_;
    my $transition = $self->getPageFlow($flow)->getTransition($state, $action);

    #this short-circuit is needed, because our special case transitions, like __bad_back_button__
    #and __set_preference__ will never have a defined transition.
    return FALSE unless $transition; 

    return $transition->getBackErrorMessage();
}


=item requires*($flow, $state, $transition)

Given a state and action from the state, returns whether a:
-validation
-revert
-commit
-freshen
-update
is required.

$flow - the page flow.
$state - the start state.
$action - the action out of the state.

=cut

sub requiresValidation {
    my ($self, $flow, $state, $action) = @_;
    my $transition = $self->getPageFlow($flow)->getTransition($state, $action);
    my $ns = Solstice::NamespaceService->new()->getAppNamespace();
    $transition = $self->getPageFlowGlobalTransition($action, $ns,$flow) unless $transition;
    $transition = $self->getGlobalTransition($action, $ns) unless $transition;

    die "Undefined transition from state '$state' via action '$action'.\n" unless $transition;
    return $transition->requiresValidation();
}

sub requiresRevert {
    my ($self, $flow, $state, $action) = @_;
    my $transition = $self->getPageFlow($flow)->getTransition($state, $action);
    my $ns = Solstice::NamespaceService->new()->getAppNamespace();
    $transition = $self->getPageFlowGlobalTransition($action, $ns,$flow) unless $transition;
    $transition = $self->getGlobalTransition($action,$ns) unless $transition;
    die "Undefined transition from state '$state' via action '$action'.\n" unless $transition;
    return $transition->requiresRevert();
}

sub requiresFresh {
    my ($self, $flow, $state, $action) = @_;
    my $transition = $self->getPageFlow($flow)->getTransition($state, $action);
    my $ns = Solstice::NamespaceService->new()->getAppNamespace();
    $transition = $self->getPageFlowGlobalTransition($action, $ns,$flow) unless $transition;
    $transition = $self->getGlobalTransition($action, $ns) unless $transition;
    die "Undefined transition from state '$state' via action '$action'.\n" unless $transition;

    return $transition->requiresFresh();
}

sub requiresCommit {
    my ($self, $flow, $state, $action) = @_;
    my $transition = $self->getPageFlow($flow)->getTransition($state, $action);
    my $ns = Solstice::NamespaceService->new()->getAppNamespace();
    $transition = $self->getPageFlowGlobalTransition($action, $ns,$flow) unless $transition;
    $transition = $self->getGlobalTransition($action, $ns) unless $transition;
    die "Undefined transition from state '$state' via action '$action'.\n" unless $transition;
    return $transition->requiresCommit();
}

sub requiresUpdate {
    my ($self, $flow, $state, $action) = @_;
    my $transition = $self->getPageFlow($flow)->getTransition($state, $action);
    my $ns = Solstice::NamespaceService->new()->getAppNamespace();
    $transition = $self->getPageFlowGlobalTransition($action, $ns,$flow) unless $transition;
    $transition = $self->getGlobalTransition($action, $ns) unless $transition;
    die "Undefined transition from state '$state' via action '$action'.\n" unless $transition;
    return $transition->requiresUpdate();
}

sub getTransition {
    my ($self, $flow, $state, $action) = @_;
    my $transition = $self->getPageFlow($flow)->getTransition($state, $action);
    unless($transition){
        return FALSE;
    }
    return $transition;
}

=item get*FailoverState*($flow, $state)

Gets the name of the failover state.

=cut

sub getValidationFailoverState {
    my ($self, $flow, $state) = @_;
    return $self->getPageFlow($flow)->getFailover($state, 'validate');
}

sub getRevertFailoverState {
    my ($self, $flow, $state) = @_;
    return $self->getPageFlow($flow)->getFailover($state, 'revert');
}

sub getCommitFailoverState {
    my ($self, $flow, $state) = @_;
    return $self->getPageFlow($flow)->getFailover($state, 'commit');
}

sub getUpdateFailoverState {
    my ($self, $flow, $state) = @_;
    return $self->getPageFlow($flow)->getFailover($state, 'update');
}

sub getValidPreConditionsFailoverState {
    my ($self, $flow, $state) = @_;
    return $self->getPageFlow($flow)->getFailover($state,
                                                  'validPreConditions');
}

sub getFreshenFailoverState {
    my ($self, $flow, $state) = @_;
    return $self->getPageFlow($flow)->getFailover($state, 'freshen');
}


=item getController($state, $application)

Gets the controller for the given state.

$state - the state to get the controller for.
$application - the application.

returns - the controller object for the $state.

=cut

sub getController {
    my ($self, $state, $application) = @_;

    my $class_name = $self->getControllerName($state);
    $self->loadModule($class_name);
    my $controller = $class_name->new($application);
    die "Controller $class_name returned undefined. \n" if !defined $controller;
    $controller->build();
    return $controller;
}


=item getControllerName($state)

Gets the name of the controller for the given state.

$state - the state to get the controller name for.

returns - the controller name (string).

=cut

sub getControllerName {
    my ($self, $state) = @_;
    my $state_object = $self->_getState($state);
    die "State $state does not exist: ".join(" ", caller)."\n" if !$state_object;
    return $state_object->getController();
}

=item _createNode($stateName, $controller)

Creates a new node object.

=cut

sub _createNode {
    my ($self, $state_name, $controller) = @_;
    return new Solstice::State::Node($state_name, $controller);
}


=item _createPageFlow($namespace, $pageflow_name, $entrance)

Creates a new page flow object.

=cut

sub _createPageFlow {
    my ($self, $namespace, $pageflow_name, $entrance) = @_;
    return new Solstice::State::PageFlow($namespace, $pageflow_name, $entrance);
}


=item _createTransition($action, $transition_final, $on_back, $lifecycle_stages)

Creates a new transition object.

=cut

sub _createTransition {
    my ($self, $action, $transition_final, $on_back, $pageflow, $lifecycle_stages) = @_;
    return new Solstice::State::Transition($action, $transition_final,
                                           $on_back, $pageflow, $lifecycle_stages);
}


=item _createFlowTransition($action, $namespace, $flowname,
                            $on_back, $lifecycle_stages)

Creates a new flow transition object.

=cut

sub _createFlowTransition {
    my ($self, $action, $namespace, $flowname, $on_back,
        $lifecycle_stages) = @_;
    return new Solstice::State::FlowTransition($action, $namespace, $flowname,
                                               $on_back,
                                               $lifecycle_stages);
}


=item _getFlowTransitionPackageName()

Returns the package name of the flow transition object.

=cut

sub _getFlowTransitionPackageName {
    my ($self) = @_;
    return "Solstice::State::FlowTransition";
}


=item _toXml()

Returns a string containing the xml serialization of the machine.

=cut

sub _toXml {
    my ($self) = @_;
    my $xml = '';
    $xml .= '<?xml version="1.0"?>'."\n";
    $xml .= '<'.XML_APPLICATION.'>'."\n";
    $xml .= '    <'.XML_STATES.'>'."\n";

    foreach my $name (sort keys %{$self->{_states}}) {
        my $controller = $self->{_states}->{$name}->getController();
        $name =~ s/.*:://;
        $xml .= '        <'.XML_STATE.' '.XML_STATE_ATTR_NAME.'="'.$name.'" '.XML_STATE_ATTR_CONTROLLER.'="'.$controller.'" />'."\n";
    }

    $xml .= '    </'.XML_STATES.'>'."\n";
    $xml .= '    <'.XML_PAGEFLOWS.'>'."\n";

    foreach my $flowname (sort keys %{$self->{_flows}}) {
        my $flow = $self->{_flows}->{$flowname};
        my $entrance = $flow->getEntrance();
        $entrance =~ s/.*:://;
        $xml .= '        <'.XML_PAGEFLOW.' '.XML_PAGEFLOW_ATTR_NAME.'="'.$flow->getName().'" '.XML_PAGEFLOW_ATTR_ENTRANCE.'="'.$entrance.'">'."\n";

        foreach my $start_state (sort keys %{$flow->getTransitions()}) {
            my $start_state_trim = $start_state;
            $start_state_trim =~ s/.*:://;
            $xml .= '            <'.XML_PAGEFLOW_STATE.' '.XML_PAGEFLOW_STATE_ATTR_NAME.'="'.$start_state_trim.'">'."\n";

            $xml .= '                <'.XML_PAGEFLOW_STATE_TRANSITIONS.'>'."\n";

            foreach my $action (sort keys %{$flow->getTransitions()->{$start_state}}) {
                my $transition = $flow->getTransition($start_state, $action);
                my $onback = $transition->getBackErrorMessage();
                if (ref($transition) eq $self->_getFlowTransitionPackageName()) {
                    # pageflow transition
                    my $application = $transition->getApplicationName();
                    my $pageflow = $transition->getPageFlowName();
                    $pageflow =~ s/^.*:://;
                    $xml .= '                    <'.XML_PAGEFLOW_STATE_BEGIN.' '.XML_PAGEFLOW_STATE_BEGIN_ATTR_ACTION.'="'.$action.'" '.XML_PAGEFLOW_STATE_BEGIN_ATTR_APPLICATION.'="'.$application.'" '.XML_PAGEFLOW_STATE_BEGIN_ATTR_PAGEFLOW.'="'.$pageflow.'"';
                    if ($onback) {
                        $xml .= ' '.XML_PAGEFLOW_STATE_BEGIN_ATTR_ONBACK.'="'.$onback.'"';
                    }
                    $xml .= '>'."\n";
                } else {
                    # traditional transition
                    my $final = $transition->getTargetState();
                    $final =~ s/.*:://;
                    $xml .= '                    <'.XML_PAGEFLOW_STATE_TRANSITION.' '.XML_PAGEFLOW_STATE_TRANSITION_ATTR_ACTION.'="'.$action.'" '.XML_PAGEFLOW_STATE_TRANSITION_ATTR_STATE.'="'.$final.'"';
                    if ($onback) {
                        $xml .= ' '.XML_PAGEFLOW_STATE_BEGIN_ATTR_ONBACK.'="'.$onback.'"';
                    }
                    $xml .= '>'."\n";
                }

                $xml .= '                        <'.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE.' '.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME.'="freshen" />'."\n" if $transition->requiresFresh();
                $xml .= '                        <'.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE.' '.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME.'="revert" />'."\n" if $transition->requiresRevert();
                $xml .= '                        <'.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE.' '.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME.'="validate" />'."\n" if $transition->requiresValidation();
                $xml .= '                        <'.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE.' '.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME.'="update" />'."\n" if $transition->requiresUpdate();
                $xml .= '                        <'.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE.' '.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME.'="commit" />'."\n" if $transition->requiresCommit();

                if (ref($transition) eq $self->_getFlowTransitionPackageName()) {
                    $xml .= '                    </'.XML_PAGEFLOW_STATE_BEGIN.'>'."\n";
                } else {
                    $xml .= '                    </'.XML_PAGEFLOW_STATE_TRANSITION.'>'."\n";
                }

            }

            $xml .= '                </'.XML_PAGEFLOW_STATE_TRANSITIONS.'>'."\n";

            $xml .= '                <'.XML_PAGEFLOW_STATE_FAILOVERS.'>'."\n";

            foreach my $failoverName (("validPreConditions", "freshen", "revert", "validate", "update", "commit")) {
                my $end_state = $flow->getFailover($start_state, $failoverName);
                if($end_state){
                    $end_state =~ s/.*:://;
                    $xml .= '                    <'.XML_PAGEFLOW_STATE_FAILOVER.' '.XML_PAGEFLOW_STATE_FAILOVER_ATTR_NAME.'="'.$failoverName.'" '.XML_PAGEFLOW_STATE_FAILOVER_ATTR_STATE.'="'.$end_state.'" />'."\n";
                }
            }

            $xml .= '                </'.XML_PAGEFLOW_STATE_FAILOVERS.'>'."\n";

            $xml .= '            </'.XML_PAGEFLOW_STATE.'>'."\n";
        }

        $xml .= '        </'.XML_PAGEFLOW.'>'."\n";
    }
    $xml .= '    </'.XML_PAGEFLOWS.'>'."\n";

    $xml .= '    <'.GLOBAL_TRANSITIONS.'>'."\n";
    foreach my $action (sort keys %{$self->{_global_transitions}{$self->{'_appNamespace'}}}) {
        my $transition = $self->{_global_transitions}{$self->{'_appNamespace'}}{$action};
        my $onback = $transition->getBackErrorMessage();
        if (ref($transition) eq $self->_getFlowTransitionPackageName()) {
            # pageflow transition
            my $application = $transition->getApplicationName();
            my $pageflow = $transition->getPageFlowName();
            $pageflow =~ s/^.*:://;
            $xml .= '        <'.XML_PAGEFLOW_STATE_BEGIN.' '.XML_PAGEFLOW_STATE_BEGIN_ATTR_ACTION.'="'.$action.'" '.XML_PAGEFLOW_STATE_BEGIN_ATTR_APPLICATION.'="'.$application.'" '.XML_PAGEFLOW_STATE_BEGIN_ATTR_PAGEFLOW.'="'.$pageflow.'"';
            if ($onback) {
                $xml .= ' '.XML_PAGEFLOW_STATE_BEGIN_ATTR_ONBACK.'="'.$onback.'"';
            }
            $xml .= '>'."\n";
        } else {

            my $final = $transition->getTargetState();
            $final =~ s/.*:://;

            $xml .= '        <'.XML_PAGEFLOW_STATE_TRANSITION.' '.XML_PAGEFLOW_STATE_TRANSITION_ATTR_ACTION.'="'.$action.'" '.XML_PAGEFLOW_STATE_TRANSITION_ATTR_STATE.'="'.$final.'"';
            if ($onback) {
                $xml .= ' '.XML_PAGEFLOW_STATE_BEGIN_ATTR_ONBACK.'="'.$onback.'"';
            }
            $xml .= '>'."\n";
        }

        $xml .= '            <'.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE.' '.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME.'="freshen" />'."\n" if $transition->requiresFresh();
        $xml .= '            <'.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE.' '.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME.'="revert" />'."\n" if $transition->requiresRevert();
        $xml .= '           <'.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE.' '.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME.'="validate" />'."\n" if $transition->requiresValidation();
        $xml .= '           <'.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE.' '.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME.'="update" />'."\n" if $transition->requiresUpdate();
        $xml .= '           <'.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE.' '.XML_PAGEFLOW_STATE_TRANSITION_LIFECYCLE_ATTR_NAME.'="commit" />'."\n" if $transition->requiresCommit();

        if (ref($transition) eq $self->_getFlowTransitionPackageName()) {
            $xml .= '        </'.XML_PAGEFLOW_STATE_BEGIN.'>'."\n";
        } else {
            $xml .= '        </'.XML_PAGEFLOW_STATE_TRANSITION.'>'."\n";
        }


    }
    $xml .= '    </'.GLOBAL_TRANSITIONS.'>'."\n";
    $xml .= '</'.XML_APPLICATION.'>'."\n";
    return $xml;
}

1;

=back

=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
