package Solution::Document;
{
    use strict;
    use warnings;
    use lib '../';
    our $VERSION = '0.9.1';
    use Solution::Variable;
    use Solution::Utility;

    #
    sub resolve { $_[0]->template->context->resolve($_[1], $_[2]); }
    sub template { $_[0]->{'template'} }
    sub parent   { $_[0]->{'parent'} }

    #sub context { return $_[0]->{'context'}; }
    #sub filters { return $_[0]->{'filters'}; }
    #sub resolve {
    #    return $_[0]->context->resolve($_[1], defined $_[2] ? $_[2] : ());
    #}
    #sub stack  { return $_[0]->context->stack($_[1]); }
    #sub scopes { return $_[0]->context->scopes; }
    #sub scope  { return $_[0]->context->scope; }
    #sub merge  { return $_[0]->context->merge($_[1]); }
    #BEGIN { our @ISA = qw[Solution::Template]; }
    sub new {
        my ($class, $args) = @_;
        raise Solution::ContextError {message => 'Missing template argument',
                                      fatal   => 1
            }
            if !defined $args->{'template'};
        return
            bless {template => $args->{'template'},
                   parent   => $args->{'template'}
            }, $class;
    }

    sub parse {
        my ($class, $args, $tokens);
        (scalar @_ == 3 ? ($class, $args, $tokens) : ($class, $tokens)) = @_;
        my $self = ref $class ? $class : $class->new($args);
    NODE: while (my $token = shift @{$tokens}) {
            if ($token =~ qr[^${Solution::Utility::TagStart}  # {%
                                (.+?)                         # etc
                              ${Solution::Utility::TagEnd}    # %}
                             $]x
                )
            {   my ($tag, $attrs) = (split ' ', $1, 2);
                my ($package, $call) = $self->template->tags->{$tag};
                if ($package
                    && ($call = $self->template->tags->{$tag}->can('new')))
                {   my $_tag =
                        $call->($package,
                                {template => $self->template,
                                 parent   => $self,
                                 tag_name => $tag,
                                 markup   => $token,
                                 attrs    => $attrs
                                }
                        );
                    push @{$self->{'nodelist'}}, $_tag;
                    if ($_tag->conditional_tag) {
                        push @{$_tag->{'blocks'}},
                            Solution::Block->new(
                                              {tag_name => $tag,
                                               attrs    => $attrs,
                                               template => $_tag->template,
                                               parent   => $_tag
                                              }
                            );
                        $_tag->parse($tokens);
                        {    # finish previous block
                            ${$_tag->{'blocks'}[-1]}{'nodelist'}
                                = $_tag->{'nodelist'};
                            $_tag->{'nodelist'} = [];
                        }
                    }
                    elsif ($_tag->end_tag) {
                        $_tag->parse($tokens);
                    }
                }
                elsif ($self->can('end_tag') && $tag =~ $self->end_tag) {
                    $self->{'markup_2'} = $token;
                    last NODE;
                }
                elsif (   $self->conditional_tag
                       && $tag =~ $self->conditional_tag)
                {   $self->push_block({tag_name => $tag,
                                       attrs    => $attrs,
                                       markup   => $token,
                                       template => $self->template,
                                       parent   => $self
                                      },
                                      $tokens
                    );
                }
                else {
                    raise Solution::SyntaxError 'Unknown tag: ' . $token;
                }
            }
            elsif (
                $token =~ qr[^
                    ${Solution::Utility::VariableStart} # {{
                        (.+?)                           #  stuff + filters?
                    ${Solution::Utility::VariableEnd}   # }}
                $]x
                )
            {   my ($variable, $filters) = split qr[\s*\|\s*], $1, 2;
                my @filters;
                for my $filter (split $Solution::Utility::FilterSeparator,
                                $filters || '')
                {   my ($filter, $args)
                        = split $Solution::Utility::FilterArgumentSeparator,
                        $filter, 2;
                    $filter =~ s[\s*$][]; # XXX - the splitter should clean...
                    $filter =~ s[^\s*][]; # XXX -  ...this up for us.
                    my @args
                        = $args ?
                        split
                        $Solution::Utility::VariableFilterArgumentParser,
                        $args
                        : ();
                    push @filters, [$filter, \@args];
                }
                push @{$self->{'nodelist'}},
                    Solution::Variable->new({template => $self->template,
                                             parent   => $self,
                                             markup   => $token,
                                             variable => $variable,
                                             filters  => \@filters
                                            }
                    );
            }
            else {
                push @{$self->{'nodelist'}}, $token;
            }
        }
        return $self;
    }

    sub render {
        my ($self) = @_;
        my $return = '';
        for my $node (@{$self->{'nodelist'}}) {
            my $rendering = ref $node ? $node->render() : $node;
            $return .= defined $rendering ? $rendering : '';
        }
        return $return;
    }
    sub conditional_tag { return $_[0]->{'conditional_tag'} || undef; }
}
1;
