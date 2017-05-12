require Tk;

package Parse::Vipar::Console;
use strict;
use Tk::Text;
use Carp;

use base 'Parse::Vipar::ViparText';
Construct Tk::Widget 'Console';
use Tk::English;

sub ClassInit
{
    my ($class,$mw) = @_;
    $class->SUPER::ClassInit($mw);
    return $class;
}

sub InitObject {
    my ($super, $args) = @_;
    $super->setprompt("&gt; ");
    $super->SUPER::InitObject($args);

    $super->{command} = $args->{-command}
      or die "-command option required";
    delete $args->{-command};

    $args->{-foreground} ||= 'darkgreen';

    $super->bind('<Key-Return>', sub {
        my $t = $_[0];
        # 1 char for the Return just pressed, since it was processed already
        # 1 char for the elven kings
        # ...and in the darkness bind them
        $t->{command}->($t->get('inputStart', 'end - 2 chars'));
        $t->_pushPrompt();
    });

    $super->{status} = $args->{-status};
    delete $args->{-status};

    $super->tagConfigure('output', -foreground => 'black');

    $super->_pushPrompt();
}

sub setprompt {
    my ($self, $prompt) = @_;
    $self->{Prompt} = $prompt;
}

sub _pushPrompt {
    my ($self) = @_;
    $self->xmlinsert('end', $self->{Prompt});
    $self->markSet('insert', 'end');
    $self->markSet('inputStart', 'end - 1 char');
    $self->markGravity('inputStart', 'left');

    # Move the window to make the prompt 2nd from the bottom?
    $self->markSet('insert', 'inputStart');
}

# Pretend that the user entered COMMAND (but do not display the next prompt)
sub userinput {
    my ($self, $command) = @_;
    $self->insert('end', $command."\n");
    $self->{command}->($command);
    $self->afterIdle(sub { $self->_pushPrompt() });
}

sub rewrite {
    my ($self, $command) = @_;
    $self->delete('inputStart', 'end');
    $self->insert('end', $command."\n");
}

# Display some output from a command
sub output {
    my ($self, $output, $tags) = @_;

    if (!defined $tags) {
	$tags = [ 'output' ];
    } elsif (!ref $tags) {
	$tags = [ $tags, 'output' ];
    } else {
	$tags = [ @$tags, 'output' ];
    }

    if (ref $output) {
        $self->window('create', 'end', -window => $output);
    } else {
        $self->xmlinsert('end', $output, $tags);
    }

    $self->see('end');
}

# Declare that the output is now complete
sub outputComplete {
    my ($self) = @_;
    $self->_pushPrompt();
}
