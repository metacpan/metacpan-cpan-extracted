
# Outthentic DSL - informal introduction

[Outthentic DSL](https://github.com/melezhik/outthentic-dsl) is a language to parse 
and validate any unstructured text. 

Two clients are based on this engine to get job done:

* [swat](https://github.com/melezhik/swat) - web application testing tool.

* [outthentic](https://github.com/melezhik/outthentic) - generic purposes testing tool.

Creating a new outthentic clients - programs using Outthentic DSL API - is quite easy and everybody welcome to get involved. 

In this document I try to highlight some essential DSL features helping in automation for text parsing, verification tasks, which are plenty of in our daily jobs, huh?

So, lets meet - outthentic DSL ...

# Basic check expressions

Check expressions are search patterns to validate original text input. 

Original text is parsed line by line and every line is matched against check expression.

If at least one line successfully matches then check succeeds, if none of lines matche then check fails. 

This procedure is repeated for all check expressions in the list. Overall check status is multiplication of intermediate checks.

There are two type of check expressions: 

* plain text expressions

* regular expressions patterns

Let see a simple example of DSL code:

     # two checks here     
     Hello # plain text expression 
     regexp: My name is outthentic\W # regular expression

This code will successfully verifies this text input:

    Hello
    My name is outthentic!
   
And won't verify this one:

    hello
    My name is outthenticz


## Multiple check expressions

As one could easily guess multiple check expressions result in logical `AND` chains for text verification procedure:

    # the input text
    # should contain
    # foo AND bar AND baz lines
    foo
    bar
    baz


# Test reports

A quick remark should be made concerning results produced by running dsl code
for examples given here.   

For the sake of simplicity of the document a test reports not show here, as emphasis is made on dsl code itself rather than on
result it yields. It should not be considered as problem though as in most of cases
verification results are _obvious_ and could be resolved out of context.


# Greedy expressions

Outthentic check expressions are greedy. 

This is what I mean when I call them greedy. Consider a trivial example:


Text input:

    1
    2
    3

DSL code:

    regexp: (\d+)
    code: print "# ", scalar @{match_lines()}


match_line() function returns an array of lines successfully matched by _latest_ check, we would talk about useful dsl functions later, but what should be important for us at the moment is 
the _number_ of elements of array returned.
 
So the question is what it should be? Not too many variants for answer here:

* 1 element - nine greedy behavior 
* 3 elements - greedy behavior

And, yes, it will return 3 elements! As outthentic parser is greedy one it tries to find 
as much as possible matching lines. In other words if parser successfully find a line
matching check expression it won't stop and try to find others, as much as possible. 

That is why the match_lines array will hold 3 lines:

    1
    2
    3

Please take this behavior into account when deal with outthentic dsl, 
sometimes it is what you expect, but sometimes it could be tricky and may "delude" you ( see [ranges expressions](#ranges) for example ) 

# Context oriented check expressions

Often we need to verify not only against single check expression, but to take into account some _context_. 

A possible cases here:

* matching against _set_ of check expressions inside some range  ( range expressions )

* matching against a continuous sequence of check expressions ( text block expressions )

Outthentic dsl provides some abstractions for such _context oriented_ matching:

* Range expressions

* Text block expressions


## Text blocks

Text blocks expressions insist that a _continuous sequence_ of lines should be found at original text input.

Consider this imaginary text output with 3 text blocks:

    <triples>
        1
        2    
        3
    </triples>     

    <triples>
        10
        20    
        30
    </triples>     

    <triples>
        foo
        bar    
        baz
    </triples>     

Now we need to ensure that triples blocks are here filled continuously by numbers or alphabetic symbol lines.  

Let's write up outthentic dsl code:


    begin:
        <triples>
            regexp \S+
            regexp \S+
            regexp \S+
        </triples>
    end:

Quite self-explanatory so far. Let's add some debugging info here:

    begin:
        <triples>

            regexp \S+
            code: print "@{match_lines}\n";

            regexp \S+
            code: print "@{match_lines}\n";

            regexp \S+
            code: print "@{match_lines}\n";

        </triples>
    end:
  
When run this code we get:

    1 10 foo
    2 20 bar
    3 30 baz

As we learned match_lines() function return array of all successfully matched lines, so the result is quite obvious.

If we want to be more specific and see pieces of lines get captured with regular expression checks we could use captures() function.

Captures() function is very similar to match_lines() function except it holds chunks relates to _regexp groups_ \(\) used at regular expression. 

Lets find only triples blocks with 2 digits numbers inside and then print out _second_ digit of every number:

     begin:
        <triples>

            regexp (\d)(\d)
            code: print "@{map {$_->[1]} @{captures()}}"

            regexp (\d)(\d)
            code: print "@{map {$_->[1]} @{captures()}}"


            regexp (\d)(\d)
            code: print "@{map {$_->[1]} @{captures()}}"

        </triples>
     end:


### Problem of not knowing the future.

So good so far, but text blocks have a shortcoming not seen at the first glance.

Consider this example.

Text input:


    1
    2

    1
    2
    3

    1
    2
    3
    4

    1
    2
    3
    4


Let's write a text block expression to capture all 4 numbers sequences:

    begin:
        regexp: \d+
        regexp: \d+
        regexp: \d+
        regexp: \d+
    end:

Obviously this code will find two block consists of 1,2,3,4 numbers. To make it clear
add debug info and see what we get:

    begin:
        regexp: \d+            
        code: print "@{match_lines}\n";

        regexp: \d+
        code: print "@{match_lines}\n";

        regexp: \d+
        code: print "@{match_lines}\n";

        regexp: \d+
        code: print "@{match_lines}\n";
    end:

The output:

    
    1 1 1 1
    2 2 2 2
    3 3 3
    4 4

Upss, not exactly what we would expect, huh? We see that outthentic parser not smart enough
and caught all the blocks (1,2 1,2,3 1,2,3,4) even though we asked only 4 numbers sequences.
_At the long run_ it left only two right ones - 1,2,3,4 but first and second iterations grabbed 2 and 3 numbers
sequences as well. 

Well the reason for this behavior is basic outthentic check expressions 
are single line context - elementary check relates only a single line - it whether matched or not, 
no other criteria or context is taken into account. Wait, but we told that text blocks are context oriented, 
did we? Yes! But this context require knowing a future - there is no way to determine if we are successful
or not till we reach the end of the sequence!

Fortunately this kind of "issue" is only relates to captures() or match_lines() functions,
but text blocks works as designed, they determine if a text contains a sequence of lines.

### Stream function as alternative to match_lines and captures 
   
Stream() function which acts _like_ match_lines() function with two essentials adjustments:

* it _accumulates_ previously matched lines

* it _groups_ matched line by group context ( text blocks in a text blocks expressions or ranges in ranges expressions )

Let's rewrite our latest code with usage of stream function
 
    begin:

        regexp: \d+
        regexp: \d+
        regexp: \d+
        regexp: \d+

        code:   
            for my $s (@{stream()}) {           \
                for my $i (@{$s}){              \
                    print $i, ' ';              \
                }                               \
            print "\next block\n";             \
        }

    end:

Now we get:

    1 2 3 4
    next block
    1 2 3 4

Much better! At least code became more concise and clear, no need to add `code:`lines after every 
regular expression check. But what is more important now we could see that test output
_respects_ original group context.


Ok, let me say it again - streams are alternative for captures. But text blocks works as designed
with streams, captures or match_lines functions. It's up to you which ones to use, it depends
on _context_.

While captures and match_lines relates to the latest expression check which is always single line context
stream instead _accumulate_ previously matched lines and _group them per blocks or ranges.

So:

* use captures() and match_lines() when you do not care about context ( not inside ranges and blocks )

* use stream() when you need to present matched data per group context


## Ranges

Range expressions looks like text blocks, but only for the first glance, they are very effective
but a bit tricky for the beginner's usage.

Let's reshape our solution for triples task. Verify that we have triples blocks with numbers inside:


     between: <triples> <\/triples> 
         regexp: \S+

That's it! More laconic than text blocks solution. A few comments here.

Between expression sets new search context, so that instead of looking
through all original input parser narrows search to area _between_ lines matching <triples>
and <\/triples> regular expression. It is very similar to what happen when one use 
[Perl range operator](http://perldoc.perl.org/perlop.html#Range-Operators) when selecting
subsets of lines out of stdin stream:
    

    while (<STDOUT>){
        if /<triples>/ ... /<\/triples>/
    }
    

Let's add some debug code to show what happening in details:


     between: <triples> <\/triples> 
         regexp: (\S+)
         code: print ( join ' ', map { $_->[0] } @{captures()} ), "\n"
     end:
    
We see then:

    1 10 foo 2 20 bar 3 30 baz

We see that regular expression check \S+ inside range expression "ate up" all
the lines in one iteration, it is ok, as we already learned that outthentic
expressions are greedy ones.

The other hurdle with range expressions.

Ranges do not preserve sort order for lines in original input

Consider this code snippet:

    # input data

    foo
        1
        2
        1
        2
    bar 

     between: foo bar 
         regexp: (1)
         code: print "# ", ( join ' ', map { $_->[0] } @{captures()} ), "\n"
         regexp: (2)
         code: print "# ", ( join ' ', map { $_->[0] } @{captures()} ), "\n"
     end:
 
A natural assumption that we get something like that:

    # 1 2
    # 1 2

But as check expression inside range blocks are greedy every expression "eat up" all the matching lines, 
so we will get this:

    # 1 1
    # 2 2

Compare with text block solution:

     begin: 
        foo 
            regexp: (\d+)
            code: print "# ", capture()->[0], "\n"
            regexp: (\d+)
            code: print "# ", capture()->[0], "\n"
            regexp: (\d+)
            code: print "# ", capture()->[0], "\n"
            regexp: (\d+)
            code: print "# ", capture()->[0], "\n"
        bar    
     end:

    # 1 
    # 2 
    # 1 
    # 2 

### Using stream() inside ranges expressions

Stream function works for ranges the same way as does for text blocks. It:

* accumulate all previously matched lines

* it group data by context

Consider this example:

Text input:


    foo
        1
    bar

    foo
        1
        2
    bar

    foo
        1
        2
        3
    bar


DSL code:


    between: foo bar
        \d+
        code:   
            for my $s (@{stream()}) {           \
                for my $i (@{$s}){              \
                    print $i, ' ';              \
                }                               \
            print "\next block\n";              \
        }
    end:


Output:

    1
    next block
    1 2
    next block
    1 2 3
        
## Multiple expressions inside ranges

Multiple expressions work inside ranges works the same as the works without range context -
they result in logical `AND` chains:

    # the input text
    # should contain
    # foo AND bar AND baz lines
    foo
    bar
    baz

    # the input text inside foo ... bar range
    # should contain
    # foo AND bar AND baz lines
    between: here there
        foo
        bar
        baz
    end:


 

## Text blocks or Ranges?

So when you want test a sequences ( continuous sets ) you need a text blocks. When you don't
care about ordering and just want to pick up some data included  in a given range you need a range
expressions. 
 
