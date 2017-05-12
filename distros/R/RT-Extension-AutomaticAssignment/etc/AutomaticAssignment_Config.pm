Set($AutomaticAssignmentFilters, [qw(
    ExcludedDates
    MemberOfGroup
    MemberOfRole
    WorkSchedule
)]) unless $AutomaticAssignmentFilters;

Set($AutomaticAssignmentChoosers, [qw(
    ActiveTickets
    Random
    RoundRobin
    TimeLeft
)]) unless $AutomaticAssignmentChoosers;

1;

