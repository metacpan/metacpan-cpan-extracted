# 1. Clear out any old, corrupted coverage data
cover -delete

# 2. Run your tests with the Devel::Cover module loaded
HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/

# 3. Generate the HTML report from the newly created cover_db
cover