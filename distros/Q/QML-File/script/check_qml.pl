#!/usr/bin/perl
use strict;
use warnings;
use QML::File;

# Parse the command-line arguments
my ($fileName) = @ARGV;
if ( !defined $fileName || @ARGV != 1 ) {
    die qq(Usage: check_qml.pl File.qml);
}

# Parse the QML file
my $parser = QML::File->new($fileName);

# Look for duplicate imports
my @imports = $parser->imports;
my %seenImports;
foreach my $import (@imports) {
    if ( exists $seenImports{$import} ) {
        print "The following import has been repeated: '$import'\n";
    }
    $seenImports{$import} = 1;
}

# Extract important parts of the QML file
my $componentName    = $parser->name;
my $objectType       = $parser->objectType;
my $id               = $parser->id;
my @properties       = $parser->propertyDeclarations;
my @signals          = $parser->signalDeclarations;
my @functions        = $parser->javaScriptFunctions;
my @objectProperties = $parser->objectProperties;
my @childObjects     = $parser->childObjects;

# Verify that the structure of the QML object has the right ordering
my $endOfId = $id ? $id->{lineNum} : 0;
my $endOfProperties = 0;
foreach my $property (@properties) {
    if ( $property->{lineNum} < $endOfId ) {
        print "Property should appear below 'id:': '$property->{line}'\n";
    }
    $endOfProperties = $property->{lineNum}
      if ( $property->{lineNum} > $endOfProperties );
}

my $endOfSignals = 0;
foreach my $signal (@signals) {
    if ( $signal->{lineNum} < $endOfProperties ) {
        print "Signal should appear below all properties: '$signal->{line}'\n";
    }
    $endOfSignals = $signal->{lineNum}
      if ( $signal->{lineNum} > $endOfSignals );
}

my $endOfFunctions = 0;
foreach my $function (@functions) {
    if ( $function->{lineNum} < $endOfSignals ) {
        print "Function should appear below all signals: '$function->{line}'\n";
    }
    $endOfFunctions = $function->{lineNum}
      if ( $function->{lineNum} > $endOfFunctions );
}

my $endOfObjectProperties = 0;
foreach my $objectProperty (@objectProperties) {
    next if ( $objectProperty->{name} =~ /^id|states|transitions$/ );
    if ( $objectProperty->{lineNum} < $endOfFunctions ) {
        print
"Object property should appear below all functions: '$objectProperty->{line}'\n";
    }
    $endOfObjectProperties = $objectProperty->{lineNum}
      if ( $objectProperty->{lineNum} > $endOfObjectProperties );
}

my $endOfChildObjects = 0;
foreach my $childObject (@childObjects) {
    if ( $childObject->{lineNum} < $endOfObjectProperties ) {
        print
"Child object should appear below all object properties: '$childObject->{line}'\n";
    }
    $endOfChildObjects = $childObject->{lineNum}
      if ( $childObject->{lineNum} > $endOfChildObjects );
}

# If there are more than two "anchors." or "font." properties, suggest grouping them
my $numAnchorProperties = grep { $_->{line} =~ /anchors\./ } @objectProperties;
if ( $numAnchorProperties > 2 ) {
    print "More than two 'anchors.*' properties. Try grouping them!\n";
}
my $numFontProperties = grep { $_->{line} =~ /font\./ } @objectProperties;
if ( $numFontProperties > 2 ) {
    print "More than two 'font.*' properties. Try grouping them!\n";
}

print "Check done.\n";

__END__

=head1 NAME

check_qml.pl - Check a QML file for some of the coding conventions described at L<http://doc.qt.io/qt-4.8/qml-coding-conventions.html>

=head1 SYNOPSIS

  perl check_qml.pl TestComponent.qml

=head1 DESCRIPTION

Check a QML file for some of the coding conventions described at L<http://doc.qt.io/qt-4.8/qml-coding-conventions.html>. Specifically, this script checks the following things:

=over

=item The ordering of the ID, properties, signals, functions, and child objects within a QML file.

=item Grouping of three or more anchors.* or font.* properties

=item Duplicate import statements

=back

=head1 SEE ALSO

C<QML::File> - Basic parsing of the high-level structure of QML files.

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Zachary D. Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
