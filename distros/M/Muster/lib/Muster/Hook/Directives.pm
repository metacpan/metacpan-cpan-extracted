package Muster::Hook::Directives;
$Muster::Hook::Directives::VERSION = '0.62';
=head1 NAME

Muster::Hook::Directives - Muster base class for preprocessor directives

=head1 VERSION

version 0.62

=head1 SYNOPSIS

  # CamelCase plugin name
  package Muster::Hook::Directives;
  use Mojo::Base 'Muster::Hook';

=head1 DESCRIPTION

L<Muster::Hook::Directives> processes for preprocessor directives.
This has sub-classes for all the directives.

As with IkiWiki, directives are prefixed with "[[!I<name>"

=cut

use Mojo::Base 'Muster::Hook';
use Carp;
use Muster::LeafFile;
use Muster::Hooks;
use YAML::Any;


=head1 METHODS

=head2 register

Initialize and register. This must be defined in a subclass.

=cut
sub register {
    croak __PACKAGE__, " register must be defined in a subclass";
}

=head2 do_directives

Extracts and processes directives from the content of the leaf.

=cut

sub do_directives {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};
    my $no_scan = $args{no_scan};
    my $directive = $args{directive};
    my $call = $args{call};

    # do nothing if this is not a page
    if (!$leaf->is_page)
    {
        return $leaf;
    }
    my $page = $leaf->pagename;
    my $content = $leaf->cooked;

    # adapted fom IkiWiki code
    my $handle=sub {
        my $escape=shift;
        my $prefix=shift;
        my $command=shift;
        my $params=shift;
        $params="" if ! defined $params;

        if (length $escape)
        {
            return "[[${prefix}${command} ${params}]]";
        }
        elsif ($phase eq $Muster::Hooks::PHASE_SCAN and $no_scan)
        {
            # save time and return immediately
            return "";
        }
        else # this already matches our directive
        {
            # Note: preserve order of params, some plugins may
            # consider it significant.
            my @params;
            while ($params =~ m{
                    (?:([-.\w]+)=)?		# 1: named parameter key?
                    (?:
                        """(.*?)"""	# 2: triple-quoted value
                        |
                        "([^"]*?)"	# 3: single-quoted value
                        |
                        '''(.*?)'''     # 4: triple-single-quote
                        |
                        <<([a-zA-Z]+)\n # 5: heredoc start
                        (.*?)\n\5	# 6: heredoc value
                        |
                        (\S+)		# 7: unquoted value
                    )
                    (?:\s+|$)		# delimiter to next param
                }msgx)
            {
                my $key=$1;
                my $val;
                if (defined $2)
                {
                    $val=$2;
                    $val=~s/\r\n/\n/mg;
                    $val=~s/^\n+//g;
                    $val=~s/\n+$//g;
                }
                elsif (defined $3)
                {
                    $val=$3;
                }
                elsif (defined $4)
                {
                    $val=$4;
                }
                elsif (defined $7)
                {
                    $val=$7;
                }
                elsif (defined $6)
                {
                    $val=$6;
                }

                if (defined $key)
                {
                    push @params, $key, $val;
                }
                else
                {
                    push @params, $val, '';
                }
            }
            if ($self->{preprocessing}->{$page}++ > 8)
            {
                # Avoid loops of preprocessed pages preprocessing
                # other pages that preprocess them, etc.
                return "[[!$command <span class=\"error\">".
                        sprintf("preprocessing loop detected on %s at depth %i",
                            $page, $self->{preprocessing}->{$page}).
                        "</span>]]";
            }
            my $ret;
            if ($phase eq $Muster::Hooks::PHASE_BUILD) # not scanning
            {
                $ret=eval {
                    $call->(%args, params=>\@params);
                };
                if ($@)
                {
                    my $error=$@;
                    chomp $error;
                    eval q{use HTML::Entities};
                    $error = encode_entities($error);
                    $ret="[[!$command <span class=\"error\">".
                            "Error".": $error"."</span>]]";
                }
            }
            else # scanning
            {
                eval {
                    $call->(%args, params=>\@params);
                };
                $ret="";
            }
            $self->{preprocessing}->{$page}--;
            return $ret;
        }
    };

    # NOTE: unlike with the IkiWiki version of directives
    # we already know WHICH directive to search for, as it is
    # one of the arguments passed in to do_directive.
    # So we aren't going to have any false positives about whether
    # this is really the command we are looking for.
    my $regex = qr{
            (\\?)		# 1: escape?
            \[\[(!)		# directive open; 2: prefix
                    ($directive)	# 3: command
                    (		# 4: the parameters..
                        \s+	# Must have space if parameters present
                        (?:
                            (?:[-.\w]+=)?		# named parameter key?
                            (?:
                                """.*?"""	# triple-quoted value
                                |
                                "[^"]*?"	# single-quoted value
                                |
                                '''.*?'''	# triple-single-quote
                                |
                                <<([a-zA-Z]+)\n # 5: heredoc start
                                (?:.*?)\n\5	# heredoc value
                                |
                                [^"\s\]]+	# unquoted value
                        )
                        \s*			# whitespace or end
                        # of directive
                    )
                    *)?		# 0 or more parameters
                \]\]		# directive closed
    }sx;

    $content =~ s{$regex}{$handle->($1, $2, $3, $4)}eg;

    $leaf->{cooked} = $content;
    return $leaf;
} # do_directives

1;
