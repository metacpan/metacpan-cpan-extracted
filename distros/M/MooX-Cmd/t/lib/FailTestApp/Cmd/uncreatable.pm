package FailTestApp::Cmd::uncreatable;

use Moo;

with "MooX::Cmd::Role";

around _build_command_creation_chain_methods => sub { [] };

sub execute {}

1;
