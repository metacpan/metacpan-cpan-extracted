package Test::BDD::Cucumber::StepMatcher;
$Test::BDD::Cucumber::StepMatcher::VERSION = '0.58';
=head1 NAME

Test::BDD::Cucumber::StepMatcher - Run through Feature and Harness objects

=head1 VERSION

version 0.58

=head1 DESCRIPTION


=cut

use Moo;



=head2 execute

Execute accepts a feature object, a harness object, and an optional
L<Test::BDD::Cucumber::TagSpec> object and for each scenario in the
feature which meets the tag requirements (or all of them, if you
haven't specified one), runs C<execute_scenario>.

=cut

sub execute {
    my ( $self, $feature, $harness, $tag_spec ) = @_;
    my $feature_stash = {};

    $harness->feature($feature);
    my @background =
      ( $feature->background ? ( background => $feature->background ) : () );

    # Get all scenarios
    my @scenarios = @{ $feature->scenarios() };

    # Filter them by the tag spec, if we have one
    if ( defined $tag_spec ) {
        @scenarios = $tag_spec->filter(@scenarios);
    }

    $_->pre_feature( $feature, $feature_stash ) for @{ $self->extensions };
    for my $scenario (@scenarios) {

        # Execute the scenario itself
        $self->execute_outline(
            {
                @background,
                scenario      => $scenario,
                feature       => $feature,
                feature_stash => $feature_stash,
                harness       => $harness
            }
        );
    }
    $_->post_feature( $feature, $feature_stash, 'no' )
      for reverse @{ $self->extensions };

    $harness->feature_done($feature);
}


sub execute_outline {
    my ( $self, $options ) = @_;
    my ( $feature, $feature_stash, $harness, $outline, $background_obj,
        $incoming_scenario_stash, $incoming_outline_state )
      = @$options{
        qw/ feature feature_stash harness scenario background scenario_stash
          outline_state
          /
      };

    # Multiply out Scenario Outlines as appropriate
    my @datasets = @{ $outline->data };
    @datasets = ( {} ) unless @datasets;


    my $is_background = $outline->background;

    my %context_defaults = (
        executor => $self,    # Held weakly by StepContext

        # Data portion
        data  => '',
        stash => {
            feature => $feature_stash,
            step    => {},
        },

        # Step-specific info
        feature  => $feature,
        scenario => $outline,

        # Communicators
        harness => $harness,

        transformers => $self->{'steps'}->{'transform'} || [],
    );

    my $outline_state = $incoming_outline_state || {};

    foreach my $dataset (@datasets) {
        my $scenario_stash = $incoming_scenario_stash || {};
        $outline_state->{'short_circuit'} ||= $self->_bail_out;
        $context_defaults{stash}->{scenario} = $scenario_stash;

        $self->execute_scenario();
    }
}


sub execute_scenario {
    # OK, back to the normal execution
    $harness->scenario( $outline, $dataset,
                        $scenario_stash->{'longest_step_line'} );

    $_->pre_scenario( $outline, $feature_stash, $scenario_stash )
        for @{ $self->extensions };

    for my $before_step ( @{ $self->{'steps'}->{'before'} || [] } ) {

        # Set up a context
        my $context = Test::BDD::Cucumber::StepContext->new(
            { %context_defaults, verb => 'before', } );

        my $result =
            $self->dispatch( $context, $before_step,
                             $outline_state->{'short_circuit'}, 0 );

        # If it didn't pass, short-circuit the rest
        unless ( $result->result eq 'passing' ) {
            $outline_state->{'short_circuit'} = 1;
        }
    }
    # Run the background if we have one. This recurses back in to
    # execute_scenario...
    if ($background_obj) {
        $harness->background(
            $outline, $dataset, $scenario_stash->{'longest_step_line'} );
        $self->execute_steps(
            {
                is_background  => 1,
                scenario       => $background_obj,
                feature        => $feature,
                feature_stash  => $feature_stash,
                harness        => $harness,
                scenario_stash => $scenario_stash,
                outline_state  => $outline_state
            }
            );
        $harness->background_done( $outline, $dataset );
    }


    $self->execute_steps(
        {
            scenario       => $outline,
            feature        => $feature,
            feature_stash  => $feature_stash,
            harness        => $harness,
            scenario_stash => $scenario_stash,
            outline_state  => $outline_state
        }
        );
    $harness->scenario_done( $outline, $dataset );

    for my $after_step ( @{ $self->{'steps'}->{'after'} || [] } ) {

        # Set up a context
        my $context = Test::BDD::Cucumber::StepContext->new(
            { %context_defaults, verb => 'after', } );

        # All After steps should happen, to ensure cleanup
        my $result = $self->dispatch( $context, $after_step, 0, 0 );
    }
    $_->post_scenario( $outline, $feature_stash, $scenario_stash,
                       $outline_state->{'short_circuit'} )
        for reverse @{ $self->extensions };
}

=head2 execute_steps

Accepts a hashref of options, and executes each step in a scenario. Options:

C<feature> - A L<Test::BDD::Cucumber::Model::Feature> object

C<feature_stash> - A hashref that should live the lifetime of feature execution

C<harness> - A L<Test::BDD::Cucumber::Harness> subclass object

C<scenario> - A L<Test::BDD::Cucumber::Model::Scenario> object

C<background_obj> - An optional L<Test::BDD::Cucumber::Model::Scenario> object
representing the Background

C<scenario_stash> - We'll create a new scenario stash unless you've posted one
in. This is used exclusively for giving Background sections access to the same
stash as the scenario they're running before.

For each step, a L<Test::BDD::Cucumber::StepContext> object is created, and
passed to C<dispatch()>. Nothing is returned - everything is played back through
the Harness interface.

=cut

sub execute_steps {
    my ( $self, $options ) = @_;
    my ( $feature, $feature_stash, $harness, $scenario, $background_obj,
        $incoming_scenario_stash )
      = @$options{
        qw/ feature feature_stash harness scenario background scenario_stash
          outline_state
          /
      };

    foreach my $step ( @{ $outline->steps } ) {

        # Multiply out any placeholders
        my $text =
            $self->add_placeholders( $step->text, $dataset, $step->line );
        my $data = $step->data;
        $data = (ref $data) ?
            $self->add_table_placeholders( $data, $dataset, $step->line )
            : (defined $data) ?
            $self->add_placeholders( $data, $dataset, $step->line )
            : '';

        # Set up a context
        my $context = Test::BDD::Cucumber::StepContext->new(
            {
                %context_defaults,

                    # Data portion
                    columns => $step->columns || [],
                    data => $data,

                    # Step-specific info
                    step => $step,
                    verb => lc( $step->verb ),
                    text => $text,
            }
            );

        my $result =
            $self->find_and_dispatch( $context,
                                      $outline_state->{'short_circuit'}, 0 );

        # If it didn't pass, short-circuit the rest
        unless ( $result->result eq 'passing' ) {
            $outline_state->{'short_circuit'}++;
        }

    }

    return;
}

=head2 add_placeholders

Accepts a text string and a hashref, and replaces C< <placeholders> > with the
values in the hashref, returning a string.

=cut

sub add_placeholders {
    my ( $self, $text, $dataset, $line ) = @_;
    my $quoted_text = Test::BDD::Cucumber::Util::bs_quote($text);
    $quoted_text =~ s/(<([^>]+)>)/
        exists $dataset->{$2} ? $dataset->{$2} :
            die parse_error_from_line( "No mapping to placeholder $1", $line )
    /eg;
    return Test::BDD::Cucumber::Util::bs_unquote($quoted_text);
}


=head2 add_table_placeholders

Accepts a hash with parsed table data and a hashref, and replaces
C< <placeholders> > with the values in the hashref, returning a copy of the
parsed table hashref.

=cut

sub add_table_placeholders {
    my ($self, $tbl, $dataset, $line) = @_;
    my @rv = map {
        my $row = $_;
        my %inner_rv =
            map { $_ => $self->add_placeholders($row->{$_}, $dataset, $line)
        } keys %$row;
        \%inner_rv;
    } @$tbl;
    return \@rv;
}





1;
