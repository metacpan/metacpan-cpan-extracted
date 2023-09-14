package Net::CLI::Interact::Transport::Platform::Win32;
$Net::CLI::Interact::Transport::Platform::Win32::VERSION = '2.400002';
use Moo;
extends 'Net::CLI::Interact::Transport::Wrapper::IPC_Run';

{
    package # hide from pause
        Net::CLI::Interact::Transport::Platform::Options;
    use Moo;
    extends 'Net::CLI::Interact::Transport::Wrapper::Options';
}

=pod

=cut

1;
