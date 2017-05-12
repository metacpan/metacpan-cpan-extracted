require "t/coretests.pm";

reset_all_tests();
initialize_results("results.yml");
run_tests("perl t/002_config");
