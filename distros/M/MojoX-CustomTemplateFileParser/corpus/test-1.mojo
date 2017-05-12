
# Code here

==test example==
Text before the test
--t--
    %= link_to 'MetaCPAN', 'http://www.metacpan.org/'
--t--
Text between template and expected
--e--
    <a href="http://www.metacpan.org/">MetaCPAN</a>
--e--
Text after expected.

==test loop(first name)==
More text
--t--
    %= text_field username => placeholder => '[var]'
--t--
--e--
    <input name="username" placeholder="[var]" type="text" />
--e--

==no test==
--t--
    %= text_field username => placeholder => 'Not tested'
--t--
--e--
    <input name="username" placeholder="Not tested" type="text" />
--e--

==test==
--t--

--t--

--e--

--e--
