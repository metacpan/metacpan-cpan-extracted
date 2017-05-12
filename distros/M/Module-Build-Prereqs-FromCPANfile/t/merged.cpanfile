
on runtime => sub {
    requires "Runtime", "1.50";
};

on build => sub {
    requires "Merged", "1.30";
};

on test => sub {
    requires "Merged", "2.10";
};

on configure => sub {
    requires "Merged";
};
