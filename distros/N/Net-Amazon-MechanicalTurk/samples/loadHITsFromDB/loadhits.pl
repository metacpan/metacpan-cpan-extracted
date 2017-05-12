#!/usr/bin/perl
use strict;
use warnings;
use Net::Amazon::MechanicalTurk;
use Net::Amazon::MechanicalTurk::RowData::SQLRowData;
use DBI;

#
# This script loadsHITs using a database query for its input data.
# Instead of writing successful hits to a success file. HITs are inserted
# into a database table.
#
# This script demonstrates the following features:
#   1. Using loadHITs for bulk loading.
#   2. Using the SQLRowData class to produce input rows from a database.
#   3. Using a custom subroutine for handling successfully created HITs.
#   4. Using a replacement value in the RequesterAnnotation field.
#   5. Turning on debugging to see calls being made against the web service.
#

sub questionTemplate {
    my %params = %{$_[0]};
    return <<END_XML;
<?xml version="1.0" encoding="UTF-8"?>
<QuestionForm xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd">
  <Question>
    <QuestionIdentifier>1</QuestionIdentifier>
    <QuestionContent>
      <Text>What is the best restaurant in $params{city}, $params{state}?</Text>
    </QuestionContent>
    <AnswerSpecification>
      <FreeTextAnswer/>
    </AnswerSpecification>
  </Question>
</QuestionForm>
END_XML
}

# This subroutine is called on every successfully loaded hit.
sub onLoadedHIT {
    my %params = @_;
    my $mturk     = $params{mturk};
    my $dbh       = $params{dbh};
    my $insertSth = $params{insertSth};
    my $question  = $params{parameters}{Question};
    my $cityid    = $params{row}{id};
    my $hitId     = $params{HITId};
    my $hitTypeId = $params{HITTypeId};
    
    $insertSth->execute($hitId, $hitTypeId, $cityid, $question);
    $dbh->commit;
}

my $properties = {
    Title       => 'LoadHITs hits from DBI connection.',
    Description => 'This is a test of the bulk loading API.',
    Keywords    => 'LoadHITs, bulkload, perl, DBI',
    Reward => {
        CurrencyCode => 'USD',
        Amount       => 0.00
    },

    # Note: the value for requester annotation may have have values
    #  from the input data substituted into it on every hit.
    #  In this case the id of the cities row is put into the annotation.
    #  (This is not a perl variable, the loadHITs method looks for substitutions.)
    RequesterAnnotation         => "City Id: \${id}",

    AssignmentDurationInSeconds => 60 * 60,
    AutoApprovalDelayInSeconds  => 60 * 60 * 10,
    MaxAssignments              => 3,
    LifetimeInSeconds           => 60 * 60
};

my $dbh = DBI->connect("dbi:SQLite2:dbname=turk.db","","", {
    RaiseError => 1,
    AutoCommit => 0
});

my $insertSth = $dbh->prepare(qq{
    INSERT INTO hits (hitid, hittypeid, cityid, question)
    VALUES (?,?,?,?)
});

my $mturk = Net::Amazon::MechanicalTurk->new;

my $data = Net::Amazon::MechanicalTurk::RowData::SQLRowData->new(
    dbh => $dbh,
    sql => "SELECT * FROM cities"
);

# This is how you can enable debugging output.
require Net::Amazon::MechanicalTurk::Transport::RESTTransport;
Net::Amazon::MechanicalTurk->debug(\*STDERR);
Net::Amazon::MechanicalTurk::Transport::RESTTransport->debug(\*STDERR);

#
# Notice the use of the anonymous subroutine for the succes parameter.
# This feature allows you to plug in your own logic for sucessfully
# load hits, such as updating your database with the HITId.
#

$mturk->loadHITs(
    properties => $properties,
    input      => $data,
    question   => \&questionTemplate,
    progress   => \*STDOUT,
    success    => sub { onLoadedHIT( dbh => $dbh, insertSth => $insertSth, @_ ); },
    fail       => "loadhits-failure.csv",
);

$dbh->commit;
$dbh->disconnect;
