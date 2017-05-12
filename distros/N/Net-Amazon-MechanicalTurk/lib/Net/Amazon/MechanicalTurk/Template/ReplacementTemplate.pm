package Net::Amazon::MechanicalTurk::Template::ReplacementTemplate;
use strict;
use warnings;
use Carp;
use IO::File;
use Net::Amazon::MechanicalTurk::Template;
use Net::Amazon::MechanicalTurk::DataStructure;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::Template };

Net::Amazon::MechanicalTurk::Template::ReplacementTemplate->attributes(qw{
    tokens
});

#
# The java command line tools for MechanicalTurk use Velocity for
# question templates.
#
# The class should handle some of the simple samples used for bulk loading
# in the java command line tools.
#
# For more powerful features PerlTemplate may be used.
#

sub compileSource {
    my ($self, $text) = @_;
    
    $self->templateSource($text);
    
    # The loop keeps chopping of chunks of text from the front.
    # It may pull out a chunk of text in the first regex group
    # and the variable name to be replaced, will be in the 3rd or 4th.
    # Variable names appear as ${variableName} or $variableName.
    # If a nested variable is needed it must be in the bracket syntax
    # with dots seperating keys or array indices (array indices 
    # start at 1).
    
    my @tokens;
    while ($text =~ s/^(.*?)(\${([^}]+)}|\$([a-zA-Z0-9\-_]+))//s) {
        my $subText = $1;
        my $var = $3;
        if (!defined($var) or $var eq "") {
            $var = $4;
        }
        my $varToken = $2;
        $var =~ s/^\s+//;
        $var =~ s/\s+$//;
        if (defined($subText) and length($subText) > 0) {
            $subText =~ s/\\{/{/g;
            $subText =~ s/\\}/}/g;
            push(@tokens, { type => 'text', text => $subText });
        }
        push(@tokens, { type => 'var', var => $var, varToken => $varToken });
    }
    
    if (length($text) > 0) {
        my $subText = $text;
        $subText =~ s/\\{/{/g;
        $subText =~ s/\\}/}/g;
        push(@tokens, { type => 'text', text => $subText });
    }
    
    $self->tokens(\@tokens);
    $self->compiled(1);
}

sub merge {
    my ($self, $params) = @_;
    my $out = '';
    foreach my $token (@{$self->tokens}) {
        if ($token->{type} eq 'text') {
            $out .= $token->{text};
        }
        else {
            my $value = Net::Amazon::MechanicalTurk::DataStructure->getFirst($params, $token->{var});
            if (defined($value) and length($value) > 0) {
                $out .= $value;
            }
        }
    }
    return $out;
}

return 1;
