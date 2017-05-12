# ==========================================
# Copyright (C) 2004 kyle dawkins
# kyle-at-centralparksoftware.com
# ObjectivePerl is free software; you can
# redistribute and/or modify it under the 
# same terms as perl itself.
# ==========================================

package ObjectivePerl::Parser;
use strict;
use Carp;

my $OBJP_START = "~[";
my $OBJP_START_MATCH_FOR_END = "[";
my $OBJP_END = "]";
my $OBJP_SUPER = 'super';

#use IF::Log;
use Text::Balanced qw(extract_codeblock);

my $_parser;

sub new {
	my $className = shift;
	return $_parser if $_parser;
	my $self = {
			_content => [],
			_currentClass => "",
			_classes => {},
		};
	bless $self, $className;
	$_parser = $self;
	return $self;
}

sub initWithFile {
	my $self = shift;
	my $fullPath = shift;

	$self->setFullPath($fullPath);
	$self->setSource(contentsOfFileAtPath($fullPath));
	$self->parse();
}

sub initWithString {
	my $self = shift;
	my $string = shift;

#	IF::Log::debug("Parser re-initialised with string ".substr($string, 0, 30)."...");
	$self->setFullPath();
	$self->setSource($string);
	$self->setContent([]);
	$self->parse();
#$self->dump();
}

sub setFullPath {
	my $self = shift;
	$self->{_fullPath} = shift;
}

sub fullPath {
	my $self = shift;
	return $self->{_fullPath};
}

sub content {
	my $self = shift;
	return $self->{_content};
}

sub setContent {
	my $self = shift;
	$self->{_content} = shift;
}

sub contentElementAtIndex {
	my $self = shift;
	my $index = shift;
	my $content = $self->content();
	return $content->[$index];
}

sub contentElementsInRange {
	my $self = shift;
	my $start = shift;
	my $end = shift;
	my $content = $self->content();
	return [$content->[$start..$end]];
}

sub contentElementCount {
	my $self = shift;
	return scalar @{$self->content()};
}

sub source {
	my $self = shift;
	return $self->{_source};
}

sub setSource {
	my $self = shift;
	$self->{_source} = shift;
}

# This is a trick to allow the perl parser
# to take over again and import and parse use'd
# classes before continuing with this class
sub shouldSuspendParsing {
	my $self = shift;
	foreach my $contentElement (@{$self->content()}) {
		return 1 if ($contentElement =~ /^no ObjectivePerl;$/m);
	}
	return 0;
}

sub parse {
	my $self = shift;
	$self->stripComments();
	$self->setContent([$self->source()]);
	$self->parseImplementationDetails();
	if ($self->shouldSuspendParsing()) {
		# Suspending parsing to allow import of parent classes
		return;
	}
	$self->breakIntoPackages();
	$self->parseMethodDefinitions();
	$self->parseMethodsForInstanceVariables();
	$self->extractMessages();
	$self->translateMessages();
	$self->postProcess();
	#$self->dump();
}

sub stripComments {
	my $self = shift;
	my $source = $self->source();
	$source =~ s/^\#OBJP/\!!OBJP/go;
	$source =~ s/^\s*\#.*$//go;
	$source =~ s/^!!OBJP/#OBJP/go;
	$self->setSource($source);
}

sub breakIntoPackages {
	my $self = shift;
	my $content = $self->content();
	my $splitContent = [];
	foreach my $contentElement (@$content) {
		while (1) {
			if ($contentElement =~ /^\s*(package\s+[A-Za-z0-9_:]+\s*;)/mo) {
				my $packageDeclaration = $1;
				$packageDeclaration =~ /package\s+([A-Za-z0-9_:]+)/o;
				my $packageName = $1;
				unless ($self->{_classes}->{$packageName}) {
					$self->{_classes}->{$packageName} = { methods => {} };
				}
				my $quotedPackageDeclaration = quotemeta($packageDeclaration);
				my ($beforePackage, $afterPackage) = split(/$quotedPackageDeclaration/, $contentElement, 2);
				my $packageVariableDeclarations = "\n\n\$".$self->{_currentClass}."::".$OBJP_SUPER." = '_SUPER';\n";
				push (@$splitContent, $beforePackage, $packageDeclaration, $packageVariableDeclarations);
				$contentElement = $afterPackage;
			} else {
				push (@$splitContent, $contentElement);
				last;
			}
		}
	}
	$self->setContent($splitContent);
}

sub parseImplementationDetails {
	my $self = shift;
	foreach my $contentElement (@{$self->content()}) {
		while ($contentElement =~ /^(\@(implementation|protocol) ([A-Za-z0-9_\:]+)( :\s*([A-Za-z0-9_\:]+))?\s*(\<\s*((([A-Za-z0-9_\:]+),?\s*)*)\s*\>)?\s*(($|\{(\s|$)*)(\s*(\@(private|protected):\s*)?\$[a-zA-Z0-9_]+\s*[;,]\s*($)?)*\})?)/mo) {
			#print "1: $1\n2: $2\n3: $3\n4: $4\n5: $5\n6: $6\n7: $7\n8: $8\n9: $9\n10: $10\n";
			my $substituteRegExp = quotemeta($1);
			my $className = $3;
			my $parentClassName = $5;
			my $protocolList = $7 || "";
			my $protocols = [split(/[, ]+/, $protocolList)];
			my $instanceDeclarations = $10;
# (($|\{\s*$)(\s*\$[a-zA-Z0-9_]+\s*[;,]\s*($)?)*\})
			my $newClassDefinition = $self->classDefinitionFromClassAndParentClassConformingToProtocols($className, $parentClassName, $protocols);
			my $ivars = instanceVariablesFromInstanceDeclarations($10);

			$self->{_classes}->{$className} = {
					parent => $parentClassName,
					protocols => $protocols,
					ivars => $ivars,
			};
			my $ivarDeclaration = "use ObjectivePerl::InstanceVariable;\n";
			$ivarDeclaration .= "\$".$self->{_currentClass}."::objp_ivs = {\n";
			foreach my $level qw(private protected) {
				next unless ($ivars->{$level});
				$ivarDeclaration .= "\t$level => [qw(".join(" ", @{$ivars->{$level}}).")],\n";
			}
			$ivarDeclaration .= "};\n";
			$newClassDefinition = $newClassDefinition.$ivarDeclaration;
			$contentElement =~ s/$substituteRegExp/$newClassDefinition/m;
		}
		$contentElement =~ s/^\@end/1;package main;\n/mg;
	}
#$self->dump();
}

sub parseMethodDefinitions {
	my $self = shift;
	foreach my $contentElement (@{$self->content()}) {
		next if (ref $contentElement eq 'ARRAY');
		#IF::Log::debug("Check element for methods: $contentElement");
		if ($contentElement =~ /^package ([A-Za-z0-9_:]+);/m) {
			$self->{_currentClass} = $1;
		}
		while ($contentElement =~ /^(([\+\-])\s*(\([a-zA-Z]+\))?\s*([a-zA-Z0-9_]+[^\{]*{))/mo) {
			my $methodType = "INSTANCE";
			my $methodLine = quotemeta("$1");
			my $methodDeclaration = $4;
			my $returnType = $3;
			if ($2 eq "+") {
				$methodType = "STATIC";
			}

			my $newMethodDefinition = methodDefinitionFromMethodTypeAndDeclaration(
										$methodType, $methodDeclaration);
			if ($returnType) {
				$returnType =~ s/[()]//g;
				$newMethodDefinition->{returnType} = $returnType;
			}
			if ($self->{_classes}->{$self->{_currentClass}}->{methods}->{$newMethodDefinition->{signature}}) {
				#IF::Log::dump($self->{_classes}->{$self->{_currentClass}}->{methods});
				croak("Warning, redefinition of method shown here: ".$newMethodDefinition->{signature}." in class ".$self->{_currentClass});
			}
			$self->{_classes}->{$self->{_currentClass}}->{methods}->{$newMethodDefinition->{signature}} = $newMethodDefinition;
			my $methodSignature = $newMethodDefinition->{signature};
			if ($self->camelBonesCompatibility()) {
				my $selector = $newMethodDefinition->{signature};
				$selector =~ s/_/:/g;
				$selector .= ":"; #??
				$methodSignature .= " : Selector($selector)";
				if ($newMethodDefinition->{argumentTypes}) {
					my $argumentList = "";
					foreach my $argumentType (@{$newMethodDefinition->{argumentTypes}}) {
						$argumentList .= argumentTypeCharacterFromArgumentTypeName($argumentType);
					}
					$methodSignature .= " ArgTypes($argumentList)";
				}
				if ($newMethodDefinition->{returnType}) {
					$methodSignature .= " ReturnType(".argumentTypeCharacterFromArgumentTypeName($newMethodDefinition->{returnType}).")";
				}
			}
			my $newMethodLine = "sub ".$methodSignature." {\n";
			$newMethodLine .= "\tmy (".join(", ", '$objp_self', @{$newMethodDefinition->{arguments}}).") = \@_;\n";
			if ($newMethodDefinition->{type} eq "INSTANCE") {
				$newMethodLine .= "\tmy \$self = \$objp_self;\n";
			} else {
				$newMethodLine .= "\tmy \$className = \$objp_self;\n";
			}
			$newMethodLine .= "#OPIV\n";
			$contentElement =~ s/$methodLine/$newMethodLine/g;
		}
	}
}

sub parseMethodsForInstanceVariables {
	my $self = shift;
	foreach my $contentElement (@{$self->content()}) {
		next if (ref $contentElement eq 'ARRAY');
		if ($contentElement =~ /^package ([A-Za-z0-9_:]+);/mo) {
			$self->{_currentClass} = $1;
		}
		my $foundMethods = [];
		while ($contentElement =~ /^\s*sub ([a-zA-Z0-9_]+)([^\{]|$)*{/mgo) {
			push (@$foundMethods, $1);
		}

		foreach my $methodName (@$foundMethods) {
#print $methodName."\n";
			my $methodDefinition = $self->{_classes}->{$self->{_currentClass}}->{methods}->{$methodName};
			my $isInstanceMethod;
			if ($methodDefinition) {
				#IF::Log::dump($methodDefinition);
				$isInstanceMethod = ($methodDefinition->{type} eq "INSTANCE");
			}
			my ($beforeSub, $afterSub) = split(/^sub $methodName.?[^\{]*/sm, $contentElement, 2);
			my @stuff = extract_codeblock($afterSub, '{}');
			my $methodBlock = $stuff[0];
			
			if ($methodBlock) {
				my $originalCode = quotemeta($methodBlock);
				
				# look through the method for ivar uses
				# also here is where we *would* check for visibility rules.  Right now,
				# all ivars are considered "protected"
				
				my $ivars = {};
				my $currentClass = $self->{_currentClass};
				my $visitedClasses = { $currentClass => 1 };
				foreach my $level qw(private protected) {
					next unless $self->{_classes}->{$currentClass}->{ivars}->{$level};
					$ivars->{$level} = [] unless $ivars->{$level};
					push (@{$ivars->{$level}}, @{$self->{_classes}->{$currentClass}->{ivars}->{$level}});
				}
				while ($currentClass = $self->{_classes}->{$currentClass}->{parent}) {
					last if ($visitedClasses->{$currentClass});
					foreach my $level qw(protected) { # eventually we'll add public but for now no
						next unless $self->{_classes}->{$currentClass}->{ivars}->{$level};
						$ivars->{$level} = [] unless $ivars->{$level};
						push (@{$ivars->{$level}}, @{$self->{_classes}->{$currentClass}->{ivars}->{$level}});
					}
					$visitedClasses->{$currentClass}++;
				}
				
				my $usedIvars = [];
				foreach my $level qw(private protected) {
					foreach my $ivar (@{$ivars->{$level}}) {
						my $quotedIvar = quotemeta($ivar);
						if ($methodBlock =~ /$quotedIvar/) {
							push (@$usedIvars, $ivar);
						}
						my $arguments = $methodDefinition? $methodDefinition->{arguments} : [];
						foreach my $argument (@$arguments) {
							if ($ivar eq $argument) {
								croak "Can't have argument with the same name as instance variable $ivar\nin method $methodName";
							}
						}
					}
				}

				my $ivarImports = "";
				if (@$usedIvars && $isInstanceMethod) {
					foreach my $ivar (@$usedIvars) {
						(my $hashKey = $ivar) =~ s/\$//;

						$ivarImports .= qq(\tmy $ivar; tie $ivar, "ObjectivePerl::InstanceVariable", \$self, "$hashKey";\n);
						# there *has* to be a way to do this with typeglobs:
						#(my $glob = $ivar) =~ s/\$/\*/;
						#$ivarImports .= qq(\t$glob = \\\${\$objp_self->{_v}->{$hashKey}};\n);
					}
				}
			
				$methodBlock =~ s/^#OPIV/$ivarImports/gsm;
				$contentElement =~ s/$originalCode/$methodBlock/;
			} else {
				print "Couldn't extract method block for $methodName\n";
			}
		}
	}
}

sub translateMessages {
	my $self = shift;
	my $content = $self->content();
	foreach my $contentElement (@$content) {
		next unless ref $contentElement eq 'ARRAY';
		$contentElement = messageInvocationForContentElements($contentElement);
	}
}

sub messageInvocationForContentElements {
	my $contentElements = shift;

	my $message;
	foreach my $contentElement (@$contentElements) {
		if (ref $contentElement eq 'ARRAY') {
			$contentElement = messageInvocationForContentElements($contentElement);
		}
		$message .= $contentElement;
	}
	
	my $receiver = extractDelimitedChunkTerminatedBy($message, " ");
	my $quotedReceiver = quotemeta($receiver);
	$message =~ s/$quotedReceiver\s*//;

	my $messageName = extractDelimitedChunkTerminatedBy($message, ":");
	my $quotedMessageName = quotemeta($messageName);
	$message =~ s/$quotedMessageName[:]?\s*//;

	my $selectorArray = "";
	my $selectors = [];
	if ($message ne '') {
		# looks like we have selectors

		my $argument = extractDelimitedChunkTerminatedBy($message, " ");
		push (@$selectors, { key => "$messageName", value => $argument });
		my $quotedArgument = quotemeta($argument);
		$message =~ s/$quotedArgument\s*//;
		while ($message ne '') {
			#IF::Log::debug("MESSAGE: $message");
			my $selector = extractDelimitedChunkTerminatedBy($message, ":");
			my $quotedSelector = quotemeta($selector);
			$message =~ s/$quotedSelector[:]\s*//;
			my $argument = extractDelimitedChunkTerminatedBy($message, " ");
			if ($selector eq "") {
				$selector = "_";
			}
			push (@$selectors, { key => "$selector", value => $argument });
			my $quotedArgument = quotemeta($argument);
			$message =~ s/$quotedArgument\s*//;
		}

		$selectorArray = "[\n";
		foreach my $selector (@$selectors) {
			$selector->{key} = quoteIfNecessary($selector->{key});
			$selectorArray .= "\t{ key => ".$selector->{key}.", value => ".$selector->{value}." },\n";
		}
		$selectorArray .= "]";
	}

	if ($receiver eq '$'.$OBJP_SUPER) {
		if ($messageName =~ /^[A-Za-z0-9_]+$/o) {
			my $methodName = ObjectivePerl::Runtime::messageSignatureFromMessageAndSelectors(
															  $messageName, $selectors);
			return '$objp_self->SUPER::'.$methodName.'('.join(",", map {$_->{value}} @$selectors).')';
		} else {
			# we need to use eval() to figure this one out...
			croak "Can't call super with dynamic message name";
		}
	}
	$messageName = quoteIfNecessary($messageName);
	$receiver = quoteIfNecessary($receiver);
	return "ObjectivePerl::Runtime->ObjpMsgSend($receiver, $messageName, $selectorArray)";
}

sub quoteIfNecessary {
	my $string = shift;
	if ($string =~ /^[A-Za-z0-9_i:]+$/) {
		$string = '"'.$string.'"';
	}
	return $string;
}

sub extractMessages {
	my $self = shift;
	$self->setContent(extractMessagesFromSource(join("", @{$self->content()})));
}

sub extractMessagesFromSource {
	my $source = shift;
	my $content = [];
	#IF::Log::debug("Extracting messages from $source");
	my $start = quotemeta($OBJP_START);
	my $end = quotemeta($OBJP_END);
	while ($source =~ /$start/i) {
		(my $beforeTag, my $afterTag) = split(/$start/, $source, 2);
		push (@$content, $beforeTag) unless $beforeTag eq "";
		my ($beforeEnd, $afterEnd) = splitSourceOnMessageEnd($afterTag);
		if ($beforeEnd =~ / /) {
			push (@$content, extractMessagesFromSource($beforeEnd));
		} else {
			push (@$content, $OBJP_START.$beforeEnd.$OBJP_END);
		}
		$source = $afterEnd;
	}
	push (@$content, $source);
	return $content;
}

sub dump {
	my $self = shift;
	my @lines = split(/\n/, join("", @{$self->content()}));
	my $lineNumber = 1;
	foreach my $line (@lines) {
		print sprintf("%03d: %s\n", $lineNumber++, $line);
	}
}

sub debug {
	my $self = shift;
	return $self->{_debug};
}

sub setDebug {
	my $self = shift;
	$self->{_debug} = shift;
}

sub camelBonesCompatibility {
	my $self = shift;
	return $self->{_camelBonesCompatibility};
}

sub setCamelBonesCompatibility {
	my $self = shift;
	$self->{_camelBonesCompatibility} = shift;
}

# static methods:

sub splitSourceOnMessageEnd {
	my $source = shift;
	my $start = quotemeta($OBJP_START);
	my $startMatchForEnd = "$start|".quotemeta($OBJP_START_MATCH_FOR_END);
	my $end = quotemeta($OBJP_END);
	my $startSource = "";
	my $tagDepth = 1;
	while (1) {
		$source =~ /($startMatchForEnd)/;
		my $startingMatch = $1;
		my @lookingForStart = split(/$startMatchForEnd/i, $source, 2);
		my @lookingForEnd = split(/$end/i, $source, 2);

		if ($#lookingForStart == 0 && $#lookingForEnd == 0) {
			croak (">>> Error parsing objp no matching ".$OBJP_END);
			return (undef, undef);
		}

		if (length($lookingForEnd[0]) < length($lookingForStart[0])) {
			$tagDepth -= 1;
			$source = $lookingForEnd[1];
			$startSource .= $lookingForEnd[0];
			if ($tagDepth > 0) {
				$startSource .= $OBJP_END;
			}
		} else {
			$tagDepth += 1;
			$source = $lookingForStart[1];
			$startSource .= $lookingForStart[0].$startingMatch;
		}

		if ($tagDepth <= 0) {
			return ($startSource, $source);
		}
	}
}

sub contentsOfFileAtPath {
	my $fullPathToFile = shift;
	
	if (open (FILE, $fullPathToFile)) {
		my $contents = join("", <FILE>);
		close (FILE);
		return $contents;
	} else {
		croak("Error opening $fullPathToFile");
		return;
	}
}

sub methodDefinitionFromMethodTypeAndDeclaration {
	my $type = shift;
	my $declaration = shift;
	
	my $declarationParts = [];
	my $arguments = [];
	my $methodDefinition = { type => $type };
	my $argumentTypes = [];
	
	while ($declaration =~ /^([a-zA-Z0-9_]*)(:|\s|$)/) {
		my $part = $1;
		my $end = $2;

		push (@$declarationParts, $part);
		$declaration =~ s/^[a-zA-Z0-9_]*:?\s*//g;
		last unless ($end eq ":");

		if ($declaration =~ /^\s*\(([^)]+)\)/) {
			push (@$argumentTypes, $1);
			$declaration =~ s/^\s*\([^)]+\)\s*//g;
		} else {
			push (@$argumentTypes, "id");
		}

		$declaration =~ s/^\s*(\$[a-zA-Z0-9_]+)\s*//g;
		push (@$arguments, $1);
	}

	$methodDefinition->{selectors}     = $declarationParts;
	$methodDefinition->{arguments}     = $arguments;
	$methodDefinition->{argumentTypes} = $argumentTypes;
	$methodDefinition->{signature}     = join("_", @$declarationParts);
	return $methodDefinition;
}

sub classDefinitionFromClassAndParentClassConformingToProtocols {
	my ($self, $className, $parentClassName, $protocols) = @_;

	my $definition = "package $className;\n";
	$definition .= "use strict;\nuse vars qw(\@ISA \$".$OBJP_SUPER.");\nuse ObjectivePerl::Object;\n";
	my @isa = ();
	if ($parentClassName) {
		unless ($self->{_classes}->{$parentClassName}) {
			$definition .= "no ObjectivePerl;\n";
			$definition .= "use $parentClassName;\n";
		}
		#eval "use $parentClassName;"; # huh?!
		push (@isa, $parentClassName);
	}
	foreach my $protocol (@$protocols) {
		push (@isa, $protocol);
		$definition .= "use $protocol;\n";
	}
	if ($parentClassName && !$self->{_classes}->{$parentClassName}) {
		$definition .= "use ObjectivePerl class => '$className';\npackage $className;\n";
	}
	#$definition .= "package $className;\n"; # just to re-set the parser to the right package
	# add our own root entity class to the @isa tree:
	push (@isa, "ObjectivePerl::Object");
	$definition .= "\@ISA = qw(".join(" ", @isa).");\n\n";
	return $definition;
}

sub postProcess {
	my $self = shift;
	if ($self->debug() & $ObjectivePerl::DEBUG_SOURCE) {
		my $isDumping = 0;
		my @lines = split(/\n/, join("", @{$self->content()}));
		my $lineNumber = 1;
		foreach my $line (@lines) {
			if ($line =~ /OBJP_DEBUG_START/) {
				$isDumping = 1;
			}
			if ($line =~ /OBJP_DEBUG_END/) {
				$isDumping= 0;
			}
			print STDOUT sprintf("%04d: %s\n", $lineNumber, $line) if $isDumping;
			$lineNumber++;
		}
	}
}

sub instanceVariablesFromInstanceDeclarations {
	my $instanceDeclarations = shift || "";
	my $instanceVariables = {};

	# split into visibility levels first
	my @parts = split(/\@/, $instanceDeclarations);
	my $visibilitySections = {};
	foreach my $part (@parts) {
		unless ($part =~ /^(private|protected)(.*)$/mso) {
			push (@{$visibilitySections->{protected}}, $part);
			next;
		}
		push (@{$visibilitySections->{$1}}, $2);
	}
	
	foreach my $level (keys %$visibilitySections) {
		foreach my $part (@{$visibilitySections->{$level}}) {
			while ($part =~ /(\$[A-Za-z0-9_]+)/g) {
				push (@{$instanceVariables->{$level}}, $1);
			}
		}
	}
	#IF::Log::dump($instanceVariables);
	return $instanceVariables;
}

# LAME:  there must be a better way
sub extractDelimitedChunkTerminatedBy {
	my $chunk = shift;
	my $terminator = shift;
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
		if ($charAt =~ /$terminator/) {
			if (isBalanced($balanced)) {
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
	if (isBalanced($balanced)) {
		return $extracted;
	} else {
		croak "Error parsing message $chunk; unbalanced ".unbalanced($balanced);
	}
	return "";
}

sub isBalanced {
	my $balanced = shift;
	foreach my $char (keys %$balanced) {
		return 0 if ($char =~ /[\[\{\(]/ && $balanced->{$char} != 0);
		return 0 if ($char =~ /["']/ && $balanced->{$char} % 2 != 0);
	}
	return 1;
}

sub unbalanced {
	my $balanced = shift;
	foreach my $char (keys %$balanced) {
		return $char if ($char =~ /[\[\{\(]/ && $balanced->{$char} != 0);
		return $char if ($char =~ /["']/ && $balanced->{$char} % 2 != 0);
	}
}

sub argumentTypeCharacterFromArgumentTypeName {
	my $typeName = shift;
	return "@" if $typeName eq "id";
	return "v" if $typeName eq "void";
	return "i" if $typeName eq "int";
	return "c" if $typeName eq "char";
	return $typeName;
}

1;
