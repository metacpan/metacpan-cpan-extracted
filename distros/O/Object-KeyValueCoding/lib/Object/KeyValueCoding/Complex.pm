package Object::KeyValueCoding::Complex;

use strict;

use Object::KeyValueCoding::Additions;
use Object::KeyValueCoding::Key;

use Carp         qw( croak   );
use Scalar::Util qw( reftype );
use List::MoreUtils qw( uniq );

sub implementation {
    my ( $class, @opts ) = @_;
    my $options = { @opts };

    my $__KEY_VALUE_ADDITIONS = {};
    if ( $options->{additions} ) {
        $__KEY_VALUE_ADDITIONS = Object::KeyValueCoding::Additions->implementation();
    }

    my $__KEY_VALUE_CODING;
    $__KEY_VALUE_CODING = {

        __setValueForKey => sub {
            my ( $self, $value, $key ) = @_;

            if ($key =~ /\.|\(/o) {
                return $__KEY_VALUE_CODING->{__setValueForKeyPath}->($self, $value, $key);
            }

            my $keyList = $__KEY_VALUE_CODING->{__setterKeyList}->($self, $key);
            if ( $key !~ /^_/ ) {
                push @$keyList, @{ $__KEY_VALUE_CODING->{__setterKeyList}->($self, "_$key") };
            }
            $keyList = [ uniq @$keyList ];

            foreach my $setMethodName ( @$keyList ) {
                if ($self->can($setMethodName)) {
                    return $self->$setMethodName($value);
                }
            }

            # TODO:kd - array-based object?
            $self->{$key} = $value;
        },

        __valueForKey => sub {
            my ( $self, $key ) = @_;

            if ($key =~ /\.|\(/o) {
                return $__KEY_VALUE_CODING->{__valueForKeyPath}->($self, $key);
            }

            # generate get method names:
            my $keyList = $__KEY_VALUE_CODING->{__accessorKeyList}->($self, $key);
            if ( $key !~ /^_/ ) {
                push @$keyList, @{ $__KEY_VALUE_CODING->{__accessorKeyList}->($self, "_$key") };
            }
            $keyList = [ uniq @$keyList ];

            foreach my $testKey (@$keyList) {
                my $getMethodName = $testKey;

                if ($self->can($getMethodName)) {
                    my $value = $self->$getMethodName();
                    return $value;
                }
            }
            if (exists $self->{$key}) {
                return $self->{$key};
            }

            if ( $__KEY_VALUE_ADDITIONS->{$key} ) {
                return $__KEY_VALUE_ADDITIONS->{$key}->();
            }
            return undef;
        },

        __valueForKeyPath => sub {
            my ( $self, $keyPath ) = @_;

            my ($currentObject, $targetKeyPathElement) = $__KEY_VALUE_CODING->{__targetObjectAndKeyForKeyPath}->($self, $keyPath);
            if ($currentObject && $targetKeyPathElement) {
                return $__KEY_VALUE_CODING->{__valueForKeyPathElementOnObject}->($targetKeyPathElement, $currentObject);
            }
            return undef;
        },

        __setValueForKeyPath => sub {
            my ( $self, $value, $keyPath ) = @_;

            my ($currentObject, $targetKeyPathElement) = $__KEY_VALUE_CODING->{__targetObjectAndKeyForKeyPath}->($self, $keyPath);
            if ($currentObject && $targetKeyPathElement) {
                $__KEY_VALUE_CODING->{__setValueForKeyOnObject}->($value, $targetKeyPathElement->{key}, $currentObject);
            }
        },


        # This is very private, static API that nobody should use except me!
        __valueForKeyPathElementOnObject => sub {
            my ( $keyPathElement, $object ) = @_;
            my $key = $keyPathElement->{key};
            unless ( $keyPathElement->{arguments} ) {
                return $__KEY_VALUE_CODING->{__valueForKeyOnObject}->( $key, $object );
            }

            return undef unless ref ($object);
            if ( $object->can( $key ) ) {
                return $object->$key(@{ $keyPathElement->{argumentValues} });
            }
            if ( $key eq "valueForKey" ||$key eq "value_for_key") {
                return $__KEY_VALUE_CODING->{__valueForKeyOnObject}->( $keyPathElement->{argumentValues}->[0], $object );
            }
            if ( $__KEY_VALUE_ADDITIONS->{$key} ) {
                return $__KEY_VALUE_ADDITIONS->{$key}->(@{ $keyPathElement->{argumentValues} });
            }
            return $__KEY_VALUE_CODING->{__valueForKeyOnObject}->( $key, $object );
        },

        __valueForKeyOnObject => sub {
            my ( $key, $object ) = @_;

            return undef unless ref ($object);
            if (UNIVERSAL::can($object, "valueForKey")) {
                return $object->valueForKey($key);
            }
            # somewhat lame
            if (UNIVERSAL::can($object, "value_for_key")) {
                return $object->value_for_key($key);
            }
            if ($__KEY_VALUE_CODING->{__isHash}->($object)) {
                my $keyList = $__KEY_VALUE_CODING->{__accessorKeyList}->($object, $key);
                if ( $key !~ /^_/ ) {
                    push @$keyList, @{ $__KEY_VALUE_CODING->{__accessorKeyList}->($object, "_$key") };
                }
                foreach my $testKey (@$keyList) {
                    if (exists $object->{$key}) {
                        return $object->{$key};
                    }
                }
                return undef;
            }
            if ($__KEY_VALUE_CODING->{__isArray}->($object)) {
                if ($key eq "#") {
                    return scalar @$object;
                }
                if ($key =~ /^\@([0-9]+)$/) {
                    my $element = $1;
                    return $object->[$element];
                }
                # enhancement 2004-05-18 as part of the asset matching system
                if ($key =~ /^[a-zA-Z0-9_]+$/o) {
                    my $values = [];
                    foreach my $item (@$object) {
                        push (@$values, $__KEY_VALUE_CODING->{__valueForKeyOnObject}->($key, $item));
                    }
                    return $values;
                }
            }
            return undef;
        },

        __setValueForKeyOnObject => sub {
            my ( $value, $key, $object ) = @_;
            return undef unless ref ($object);
            if (UNIVERSAL::can($object, "setValueForKey")) {
                $object->setValueForKey($value, $key);
                return;
            }
            if (UNIVERSAL::can($object, "set_value_for_key")) {
                $object->set_value_for_key($value, $key);
                return;
            }
            if ($__KEY_VALUE_CODING->{__isHash}->($object)) {
                $object->{$key} = $value;
                return;
            }
            if ($__KEY_VALUE_CODING->{__isArray}->($object)) {
                if ($key =~ /^\@([0-9]+)$/) {
                    my $element = $1;
                    $object->[$element] = $value;
                    return
                }
                # enhancement 2004-05-18 as part of the asset matching system
                if ($key =~ /^[a-zA-Z0-9_]+$/o) {
                    my $values = [];
                    foreach my $item (@$object) {
                        $__KEY_VALUE_CODING->{__setValueForKeyOnObject}->($value, $key, $item);
                    }
                }
            }
        },

        # This returns the *second-to-last* object in the keypath
        __targetObjectAndKeyForKeyPath => sub {
            my ( $self, $keyPath ) = @_;

            my $keyPathElements = $__KEY_VALUE_CODING->{__keyPathElementsForPath}->($keyPath);

            # first evaluate any args
            foreach my $element (@$keyPathElements) {
                next unless ($element->{arguments});
                my $argumentValues = [];
                foreach my $argument (@{$element->{arguments}}) {
                    if ($__KEY_VALUE_CODING->{__expressionIsKeyPath}->($argument)) {
                        push (@$argumentValues, $__KEY_VALUE_CODING->{__valueForKey}->($self, $argument));
                    } else {
                        push (@$argumentValues, $__KEY_VALUE_CODING->{__evaluateExpression}->($self, $argument));
                    }
                }
                $element->{argumentValues} = $argumentValues;
            }

            my $currentObject = $self;

            for (my $keyPathIndex = 0; $keyPathIndex < $#$keyPathElements; $keyPathIndex++) {
                my $keyPathElement = $keyPathElements->[$keyPathIndex];
                my $keyPathValue = $__KEY_VALUE_CODING->{__valueForKeyPathElementOnObject}->($keyPathElement, $currentObject);
                if (ref $keyPathValue) {
                    $currentObject = $keyPathValue;
                } else {
                    return (undef, undef);
                }
            }
            return ($currentObject, $keyPathElements->[$#$keyPathElements]);
        },

        # TODO: will flesh this out later
        __accessorKeyList => sub {
            my ( $class, $key ) = @_;
            my $name = Object::KeyValueCoding::Key->new( $key );
            return [
                $key,
                $name->asCamelCaseProperty(),
                $name->asUnderscoreyProperty(),
                $name->asCamelCaseGetter(),
                $name->asUnderscoreyGetter(),
            ];
        },

        __setterKeyList => sub {
            my ( $class, $key ) = @_;
            my $name = Object::KeyValueCoding::Key->new( $key );
            return [
                $name->asCamelCaseSetter(),
                $name->asUnderscoreySetter(),
                $name->asCamelCase(),
                $name->asUnderscorey(),
                $key,
            ];
        },

        __camelCase => sub {
            my ( $name ) = @_;

            if ($name =~ /^[A-Z0-9_]+$/o) {
                return lcfirst(join("", map {ucfirst(lc($_))} split('_', $name)));
            }
            return $name;
        },

        # It's easier to do it this way than to import Text::Balanced
        __extractDelimitedChunkTerminatedBy => sub {
            my ( $chunk, $terminator ) = @_;
            my $extracted = "";
            my $balanced = {};
            my $isQuoting = 0;
            my $outerQuoteChar = '';

            my @chars = split(//, $chunk);
            for (my $i = 0; $i <= $#chars; $i++) {
                my $charAt = $chars[$i];

                if ($charAt eq '\\') {
                    $extracted .= $chars[$i].$chars[$i+1];
                    $i++;
                    next;
                }
                if ($charAt eq $terminator) {
                    if ($__KEY_VALUE_CODING->{__isBalanced}->($balanced)) {
                        return $extracted;
                    }
                }

                unless ($isQuoting) {
                    if ($charAt =~ /["']/) { #'"
                        $isQuoting = 1;
                        $outerQuoteChar = $charAt;
                        $balanced->{$charAt} ++;
                    } elsif ($charAt =~ /[\[\{\(]/ ) {
                        $balanced->{$charAt} ++;
                    } elsif ($charAt eq ']') {
                        $balanced->{'['} --;
                    } elsif ($charAt eq '}') {
                        $balanced->{'{'} --;
                    } elsif ($charAt eq ')') {
                        $balanced->{'('} --;
                    }
                } else {
                    if ($charAt eq $outerQuoteChar) {
                        $isQuoting = 0;
                        $outerQuoteChar = '';
                        $balanced->{$charAt} ++;
                    }
                }

                $extracted .= $charAt;
            }
            if ($__KEY_VALUE_CODING->{__isBalanced}->($balanced)) {
                return $extracted;
            } else {
                # explode?
                croak "oh bugger - Error parsing keypath $chunk; unbalanced '".$__KEY_VALUE_CODING->{__unbalanced}->($balanced)."'";
            }
            return "";
        },

        __isBalanced => sub {
            my ( $balanced ) = @_;
            foreach my $char (keys %$balanced) {
                return 0 if ($char =~ /[\[\{\(]/ && $balanced->{$char} != 0);
                return 0 if ($char =~ /["']/ && $balanced->{$char} % 2 != 0); #'"
            }
            return 1;
        },

        __unbalanced => sub {
            my ( $balanced ) = @_;
            foreach my $char (keys %$balanced) {
                return $char if ($char =~ /[\[\{\(]/ && $balanced->{$char} != 0);
                return $char if ($char =~ /["']/ && $balanced->{$char} % 2 != 0); #'"
            }
        },

        __keyPathElementsForPath => sub {
            my ( $path ) = @_;

            return [ map { {key => $_} } split(/\./, $path)] unless ($path =~ /[\(\)]/);

            my $keyPathElements = [];
            while (1) {
                my ($firstElement, $rest) = split(/\./, $path, 2);
                $firstElement ||= "";
                $rest ||= "";
                if ($firstElement =~ /([a-zA-Z0-9_\@]+)\(/) {
                    my $key = $1;
                    my $element = quotemeta($key."(");
                    $path =~ s/$element//;
                    my $argumentString = $__KEY_VALUE_CODING->{__extractDelimitedChunkTerminatedBy}->($path, ')');
                    my $quotedArguments = quotemeta($argumentString.")")."\.?";
                    # extract arguments:
                    my $arguments = [];
                    while (1) {
                        my $argument = $__KEY_VALUE_CODING->{__extractDelimitedChunkTerminatedBy}->($argumentString, ",");
                        last unless $argument;
                        push (@$arguments, $argument);
                        my $quotedArgument = quotemeta($argument).",?\\s*";
                        $argumentString =~ s/$quotedArgument//;
                    }
                    push (@$keyPathElements, { key => $key, arguments => $arguments });
                    $path =~ s/$quotedArguments//;
                } else {
                    push (@$keyPathElements, { key => $firstElement }) if $firstElement;
                    $path = $rest;
                }
                last unless $rest;
            }
            return $keyPathElements;
        },

        __evaluateExpression => sub {
            my ( $self, $expression ) = @_;
            return eval $expression;
        },


        # Stole this from Craig's tagAttribute code.  It takes a string template
        # like "foo fah fum ${twiddle.blah.zap} tiddly pom" and a language (which
        # you can use in your evaluations) and returns the string with the
        # resolved keypaths interpolated.
        __stringWithEvaluatedKeyPathsInLanguage => sub {
            my ( $self, $string, $language ) = @_;
            return "" unless $string;
            my $count = 0;
            while ($string =~ /\$\{([^}]+)\}/g) {
                my $keyValuePath = $1;
                my $value = "";

                if ($__KEY_VALUE_CODING->{__expressionIsKeyPath}->($keyValuePath)) {
                    $value = $__KEY_VALUE_CODING->{__valueForKeyPath}->($self, $keyValuePath);
                } else {
                    $value = eval "$keyValuePath"; # yikes, dangerous!
                }

                #\Q and \E makes the regex ignore the inbetween values if they have regex special items which we probably will for the dots (.).
                $string =~ s/\$\{\Q$keyValuePath\E\}/$value/g;
                #Avoiding the infinite loop...just in case
                last if $count++ > 100; # yikes!
            }
            return $string;
        },


        __isArray => sub {
            my ( $object ) = @_;
            return reftype($object) eq "ARRAY";
        },

        __isHash => sub {
            my ( $object ) = @_;
            return reftype($object) eq "HASH";
        },

        __expressionIsKeyPath => sub {
            my $expression = shift;
            return 1 if ( $expression =~ /^[A-Za-z_\(\)]+[A-Za-z0-9_#\@\.\(\)\"]*$/o );
            return ( $expression =~ /^[A-Za-z_\(\)]+[A-Za-z0-9_#\@]*(\(|\.)/o );
        },
    };
    return $__KEY_VALUE_CODING;
}

1;