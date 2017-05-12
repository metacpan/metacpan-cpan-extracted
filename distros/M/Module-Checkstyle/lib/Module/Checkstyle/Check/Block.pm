package Module::Checkstyle::Check::Block;

use strict;
use warnings;

use Carp qw(croak);
use Readonly;

use Module::Checkstyle::Util qw(:problem :args);

use base qw(Module::Checkstyle::Check);

# The directives we provide
Readonly my $DEFAULT_STYLE => 'default-style';
Readonly my $OPENING_CURLY => 'opening-curly';
Readonly my $CLOSING_CURLY => 'closing-curly';
Readonly my $IGNORE_SAME   => 'ignore-on-same-line';

# Default styles for well known bracketing
Readonly my %STYLE => (
                       'bsd' => {
                                 $OPENING_CURLY => 'alone',
                                 $CLOSING_CURLY => 'alone',
                                 $IGNORE_SAME   => 1,
                             },
                       'gnu' => {
                                 $OPENING_CURLY => 'alone',
                                 $CLOSING_CURLY => 'alone',
                                 $IGNORE_SAME   => 1,
                             },
                       'k&r' => {
                                 $OPENING_CURLY  => 'same',
                                 $CLOSING_CURLY => 'same',
                                 $IGNORE_SAME   => 1,
                             },
                       'wts' => {
                                 $OPENING_CURLY => 'alone',
                                 $CLOSING_CURLY => 'alone',
                                 $IGNORE_SAME   => 1,
                             },
                       'pbp' => {
                                 $OPENING_CURLY => 'same',
                                 $CLOSING_CURLY => 'alone',
                                 $IGNORE_SAME   => 1,
                             }
                   );

sub register {
    return (
            'PPI::Structure::Block' => \&handle_block,
        );
}

sub new {
    my ($class, $config) = @_;
    
    my $self = $class->SUPER::new($config);

    # Set defaults if such is configured
    if ($config->get_directive($DEFAULT_STYLE)) {
        my $default_style = lc($config->get_directive($DEFAULT_STYLE));
        if (exists $STYLE{$default_style}) {
            for my $directive (keys %{$STYLE{$default_style}}) {
                $self->{$directive} = $STYLE{$default_style}->{$directive};
            }
        }
    }
    
    # Opening curly
    my $opening_curly = $config->get_directive($OPENING_CURLY);
    if ($opening_curly) {
        croak qq/Invalid setting '$opening_curly' for directive '$OPENING_CURLY' in [Block]/ if !is_valid_position($opening_curly);
        $self->{$OPENING_CURLY} = lc($opening_curly);
    }

    # Closing curly
    my $closing_curly = $config->get_directive($CLOSING_CURLY);
    if ($closing_curly) {
        croak qq/Invalid setting '$closing_curly' for directive '$CLOSING_CURLY' in [Block]/ if !is_valid_position($closing_curly);
        $self->{$CLOSING_CURLY} = lc($closing_curly);
    }

    # Ignore same line
    my $ignore_same_line = $config->get_directive($IGNORE_SAME);
    if ($ignore_same_line) {
        $self->{$IGNORE_SAME} = as_true($ignore_same_line);
    }
    
    return $self;
}

Readonly my %HANDLE_PARENT_STATEMENT => (
                                        'PPI::Statement'            => 1,
                                        'PPI::Statement::Compound'  => 1,
                                        'PPI::Statement::Scheduled' => 1,
                                        'PPI::Statement::Sub'       => 1,
                                        'PPI::Statement::Variable'  => 1,
                                    );

sub handle_block {
    my ($self, $block, $file) = @_;

    # This exists to support C<my @x = grep { defined } @y>, C<my $v = sub {};> etc.
    # since it's very very common
    if (exists $self->{$IGNORE_SAME} && $self->{$IGNORE_SAME}) {
        my $opening_curly = $block->first_token(); # That is the '{'
        my $closing_curly = $block->last_token(); # That is the '}'
        return () if $opening_curly->location()->[0] == $closing_curly->location()->[0];
    }

    my @problems;

    # Check opening and closing curlies
    push @problems, $self->_handle_opening_curly($block, $file);
    push @problems, $self->_handle_closing_curly($block, $file);

    return @problems;
}

sub _handle_opening_curly {
    my ($self, $block, $file) = @_;

    my @problems;

    my $mode = $self->{$OPENING_CURLY};
    if ($mode) {
        # Check parent to see if we should handle this block
        my $statement = $block->statement();
        return () if !$statement;
        return () if !exists $HANDLE_PARENT_STATEMENT{ref $statement};

        my $opening_curly = $block->first_token(); # That is the '{'
        my $previous_sibling = $block->sprevious_sibling();

        if ($previous_sibling) {
            my $owner = $previous_sibling->last_token();
            my $curly_on_line = $opening_curly->location()->[0];
            my $owner_on_line = $owner->location()->[0];
            
            if ($mode eq 'same') {
                if ($curly_on_line != $owner_on_line) {
                    push @problems, new_problem($self->config, $OPENING_CURLY,
                                                qq/Opening curly is on its own line/,
                                                $opening_curly,
                                                $file);
                }
            }
            elsif ($mode eq 'alone') {
                if ($curly_on_line - 1 != $owner_on_line) {
                    push @problems, new_problem($self->config, $OPENING_CURLY,
                                                qq/Opening curly is not the first new line/,
                                                $opening_curly,
                                                $file);
                }
            }
        }
    }
    
    return @problems;
}

sub _handle_closing_curly {
    my ($self, $block, $file) = @_;

    my @problems;

    my $mode = $self->{$CLOSING_CURLY};
    if ($mode) {
        # Check parent to see if we should handle this block
        my $statement = $block->statement();
        return () if !$statement;
        return () if !exists $HANDLE_PARENT_STATEMENT{ref $statement};

        my $closing_curly        = $block->last_token(); # That is the '}'
        my $closing_curly_line   = $closing_curly->location()->[0];
        my $next_statement       = $block->snext_sibling();
        my @block_contents       = $block->schildren();
        my $last_block_statement = pop @block_contents;
        my $previous_statement   = defined $last_block_statement ? $last_block_statement->last_token() : undef;
        
        if ($mode eq 'same') {
            if (ref $next_statement && $next_statement->isa('PPI::Token::Word') &&
                $closing_curly_line != $next_statement->location()->[0]) {
                my $word = $next_statement->content();
                push @problems, new_problem($self->config(), $CLOSING_CURLY,
                                            qq/Closing curly is not on the same line as following '$word'/,
                                            $closing_curly,
                                            $file);
            }
        }
        elsif ($mode eq 'alone') {
            if (ref $next_statement && $next_statement->isa('PPI::Token::Word') &&
                $closing_curly_line == $next_statement->location()->[0]) {
                my $word = $next_statement->content();
                push @problems, new_problem($self->config(), $CLOSING_CURLY,
                                            qq/Closing curly is on the same line as following '$word'/,
                                            $closing_curly,
                                            $file);
            }
            
            if (ref $previous_statement &&
                $closing_curly_line == $previous_statement->location()->[0]) {
                push @problems, new_problem($self->config(), $CLOSING_CURLY,
                                            qq/Closing curly is on the same line as the preceding statement/,
                                            $closing_curly,
                                            $file);
            }
        }
    }
    
    return @problems;
}

1;
__END__

=head1 NAME

Module::Checkstyle::Check::Block - Check bracketing etc.

=head1 CONFIGURATION DIRECTIVES

=over 4

=item Default block style

Sets default values for I<opening-curly>, I<closing-curly> and I<ignore-on-same-line>. The following default styles are available:

=over 4

=item BSD/Allman (bsd)

Opening and closing curly brackets are placed on lines by themselves.

  if(x == y)
  {
      something();
  }
  else
  {
      somethingelse();
  }

Defaults are C<opening-curly = alone>, C<closing-curly = alone> and C<ignore-on-same-line = true>.

=item GNU (gnu)

Opening and closing curly brackets are placed on lines by themselves
 
  if (x == y)
    {
      something ();
    }
  else
    {
      somethingelse ();
    }

Defaults are C<opening-curly = alone>, C<closing-curly = alone> and C<ignore-on-same-line = true>.

=item K&R (k&r)

Opening curly bracket is placed on the same line as the keyword that defined the block.

  if (x == y) {
       something();
  } else {
      somethingelse();
  }

Defaults are C<opening-curly = same>, C<closing-curly = same> and C<ignore-on-same-line = true>.

=item Whitesmiths (wts)

 if (x == y)
     {
     something();
     }
 else
     {
     somethingelse();
     }


Defaults are C<opening-curly = alone>, C<closing-curly = alone> and C<ignore-on-same-line = true>.

=item Perl Best Practices (pbp)

 if (x == y) {
     something();
 }
 else {
     somethingelse();
 }

Defaults are C<opening-curly = same>, C<closing-curly = alone> and C<ignore-on-same-line = true>.

=back

=item Opening curly position

Controls the position of an opening curly bracket. Set I<opening-curly> to either 'alone' or 'same'.

C<opening-curly = alone | same>

=item Closing curly position

Controls the position of a closing curly bracket. Set I<closing-curly> to either 'alone' or same'.

C<closing-curly = alone | same>

=item Ignore curly positions when they appear on the same line

Set I<ignore-on-same-line> to a true value to ignore I<opening-curly> and I<closing-curly> when the
curlies appear on the same line. This is useful for expressions such as C<my @x = map { $_ + 1 } @y;>.

C<ignore-on-same-line = true>

=back

=begin PRIVATE

=head1 METHODS

=over 4

=item register

Called by C<Module::Checkstyle> to get events we respond to.

=item new ($config)

Creates a new C<Module::Checkstyle::Check::Package> object.

=item handle_block ($block, $file)

Called when we encounter a C<PPI::Structure::Block> element.

=back

=end PRIVATE

=head1 SEE ALSO

Writing configuration files. L<Module::Checkstyle::Config/Format>

L<Module::Checkstyle>

=cut
