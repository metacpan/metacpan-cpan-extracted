package TestHelper;
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use Test::More;

our @ISA = qw{ Net::Amazon::MechanicalTurk };

sub init {
    my $self = shift;
    $self->serviceUrl('https://mechanicalturk.sandbox.amazonaws.com');
    eval {
      $self->SUPER::init(@_); 
    };
    if ($@) {
      if ($@ =~ m/^Missing value for/) {
        plan skip_all => "Configure Amazon AWS Authentication to enable tests against Mechanical Turk Sandbox\n" . $@;
      } 
      else {
        die $@
      }
    }
}

sub sampleQuestion {
    my $xml = <<END_XML;
  <QuestionForm xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd">
    <Overview>
      <Title>Test Create HIT</Title>
      <Text>Test Create HIT</Text>
    </Overview>
    <Question>
      <QuestionIdentifier>t.1</QuestionIdentifier>
      <DisplayName>This is a test create hit.</DisplayName>
      <IsRequired>true</IsRequired>
      <QuestionContent>
        <Text>
          This should be disposed.
        </Text>
      </QuestionContent>
      <AnswerSpecification>
        <FreeTextAnswer/>
      </AnswerSpecification>
    </Question>
  </QuestionForm>
END_XML
    return $xml;
}

sub newHIT {
    my $self = shift;
    my %params = @_;

    my $xml = $self->sampleQuestion();
    my %callParams = (
        Title                       => 'Auto created test hit.',
        Description                 => 'Auto created test hit.',
        MaxAssignments              => 1,
        Reward                      => { Amount => 0.01, CurrencyCode => 'USD' },
        Question                    => $xml, 
        AssignmentDurationInSeconds => 600,
        LifetimeInSeconds           => 600,
        Keywords                    => "Test HIT"
    );
    
    while (my ($k,$v) = each %params) {
        $callParams{$k} = $v;
    }
    
    return $self->CreateHIT(%callParams);
}

sub destroyHIT {
    my ($self, $hit) = @_;
    my $hitId = (UNIVERSAL::isa($hit, "HASH")) ? $hit->{HITId} : $hit;
    
    my $assignments = $self->GetAssignmentsForHITAll(
        HITId => $hitId,
        AssignmentStatus => 'Submitted'
    );
    
    while (my $assignment = $assignments->next) {
        $self->ApproveAssignment( AssignmentId => $assignment->{AssignmentId}[0] );
    }
    
    $hit = $self->GetHIT( HITId => $hitId );
    if ($hit->{HITStatus}[0] =~ /^(Assignable|Unassignable)$/) {
        $self->DisableHIT( HITId => $hitId );
    }
    else {
        $self->DisposeHIT( HITId => $hitId );
    }
}

sub expectError {
    my ($self, $error, $block) = @_;
    eval {
        $block->();
    };
    if ($@) {
        my $errorCode = $self->response->errorCode;
        if ($error ne $errorCode) {
            fail("Expected error $error but received $errorCode.");
            return 0;
        }
        return 1;
    }
    else {
        fail("No error encountered.");
        return 0;
    }
}

return 1;
