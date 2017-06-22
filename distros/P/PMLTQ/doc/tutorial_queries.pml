<?xml version="1.0" encoding="utf-8"?>

<tree_query xmlns="http://ufal.mff.cuni.cz/pdt/pml/">
 <head>
  <schema href="tree_query_schema.xml" />
 </head>
 <q-trees>
  <LM id="q-08-12-02_145647">
   <q-nodes>
    <node>
     <node-type>t-node</node-type>
     <q-children>
      <node>
       <node-type>t-node</node-type>
       <relation>
        <child />
       </relation>
      </node>
      <test operator="=">
       <a>functor</a>
       <b>"DPHR"</b>
      </test>
     </q-children>
    </node>
   </q-nodes>
  </LM>
  <LM id="q-08-12-02_161611">
   <q-nodes>
    <node>
     <node-type>t-node</node-type>
     <q-children>
      <node>
       <node-type>t-node</node-type>
       <relation>
        <child />
       </relation>
      </node>
      <or>
       <test operator="=">
        <a>functor</a>
        <b>"DPHR"</b>
       </test>
       <test operator="=">
        <a>functor</a>
        <b>"CPHR"</b>
       </test>
      </or>
     </q-children>
    </node>
   </q-nodes>
  </LM>
  <LM id="q-08-12-02_220540">
   <q-nodes>
    <node>
     <node-type>t-node</node-type>
     <q-children>
      <node>
       <node-type>t-node</node-type>
       <relation>
        <child />
       </relation>
      </node>
      <test operator="=">
       <a>functor</a>
       <b>"DPHR"</b>
      </test>
     </q-children>
    </node>
   </q-nodes>
  </LM>
  <LM id="q-08-12-03_102434">
   <q-nodes>
    <node>
     <node-type>t-node</node-type>
     <q-children>
      <node>
       <node-type>t-node</node-type>
       <q-children>
        <ref>
         <relation>
          <user-defined label="a/lex.rf" />
         </relation>
         <target>a0</target>
        </ref>
       </q-children>
      </node>
      <ref>
       <relation>
        <user-defined label="a/lex.rf" />
       </relation>
       <target>a1</target>
      </ref>
     </q-children>
    </node>
    <node>
     <name>a0</name>
     <node-type>a-node</node-type>
     <q-children>
      <node>
       <name>a1</name>
       <node-type>a-node</node-type>
      </node>
     </q-children>
    </node>
   </q-nodes>
  </LM>
  <LM id="q-08-12-03_102518">
   <q-nodes>
    <node>
     <node-type>t-node</node-type>
     <q-children>
      <test operator="=">
       <a>t_lemma</a>
       <b>'#Rcp'</b>
      </test>
      <not>
       <subquery>
        <node-type>t-node</node-type>
        <relation>
         <user-defined label="coref_gram" />
        </relation>
        <occurrences>
         <min>1</min>
         <max>1</max>
        </occurrences>
       </subquery>
      </not>
     </q-children>
    </node>
   </q-nodes>
  </LM>
  <LM id="q-08-12-03_102529">
   <q-nodes>
    <node>
     <node-type>t-node</node-type>
     <q-children>
      <node>
       <node-type>t-node</node-type>
       <relation>
        <user-defined label="echild" />
       </relation>
       <q-children>
        <test operator="=">
         <a>functor</a>
         <b>'DPHR'</b>
        </test>
       </q-children>
      </node>
      <node>
       <node-type>t-node</node-type>
       <relation>
        <user-defined label="echild" />
       </relation>
       <q-children>
        <test operator="=">
         <a>functor</a>
         <b>'DPHR'</b>
        </test>
       </q-children>
      </node>
     </q-children>
    </node>
   </q-nodes>
  </LM>
  <LM id="q-08-12-03_102535">
   <q-nodes>
    <node>
     <name>a</name>
     <node-type>t-node</node-type>
     <q-children>
      <test operator="=">
       <a>gram/sempos</a>
       <b>'v'</b>
      </test>
      <not>
       <subquery>
        <node-type>t-node</node-type>
        <relation>
         <user-defined label="echild" />
        </relation>
        <q-children>
         <test operator="in">
          <a>functor</a>
          <b>{ 'ACT','PAT','ADDR','ORIG','EFF' }</b>
         </test>
        </q-children>
        <occurrences>
         <min>1</min>
        </occurrences>
       </subquery>
      </not>
     </q-children>
    </node>
   </q-nodes>
  </LM>
  <LM id="q-08-12-03_102622">
   <q-nodes>
    <node>
     <node-type>t-node</node-type>
     <q-children>
      <subquery>
       <node-type>t-node</node-type>
       <relation>
        <user-defined label="eparent" />
       </relation>
       <occurrences>
        <min>0</min>
        <max>0</max>
       </occurrences>
      </subquery>
     </q-children>
    </node>
   </q-nodes>
  </LM>
  <LM id="q-08-12-03_102634">
   <q-nodes>
    <node>
     <node-type>t-node</node-type>
     <q-children>
      <subquery>
       <node-type>t-node</node-type>
       <relation>
        <user-defined label="eparent" />
       </relation>
       <occurrences>
        <min>0</min>
        <max>0</max>
       </occurrences>
      </subquery>
      <test operator="~">
       <a>gram/sempos</a>
       <b>'^n'</b>
      </test>
      <not>
       <test operator="~">
        <a>functor</a>
        <b>'^(PAR|DENOM)$'</b>
       </test>
      </not>
     </q-children>
    </node>
   </q-nodes>
  </LM>
  <LM id="q-08-12-03_102651">
   <q-nodes>
    <node>
     <name>ref0</name>
     <node-type>a-node</node-type>
     <q-children>
      <not>
       <test operator="~">
        <a>m/tag</a>
        <b>'^C'</b>
       </test>
      </not>
      <node>
       <name>ref1</name>
       <node-type>a-node</node-type>
       <relation>
        <user-defined label="echild" />
       </relation>
       <q-children>
        <not>
         <test operator="~">
          <a>m/tag</a>
          <b>'^C'</b>
         </test>
        </not>
       </q-children>
      </node>
     </q-children>
    </node>
    <node>
     <node-type>t-node</node-type>
     <q-children>
      <ref>
       <relation>
        <user-defined label="a/lex.rf" />
       </relation>
       <target>ref1</target>
      </ref>
      <node>
       <node-type>t-node</node-type>
       <relation>
        <user-defined label="echild" />
       </relation>
       <q-children>
        <ref>
         <relation>
          <user-defined label="a/lex.rf" />
         </relation>
         <target>ref0</target>
        </ref>
       </q-children>
      </node>
     </q-children>
    </node>
   </q-nodes>
  </LM>
  <LM id="q-08-12-03_102730">
   <q-nodes>
    <node>
     <node-type>t-node</node-type>
     <q-children>
      <test operator="=">
       <a>functor</a>
       <b>'DPHR'</b>
      </test>
      <subquery>
       <node-type>t-node</node-type>
       <relation>
        <child label="child" />
       </relation>
       <occurrences>
        <min>2</min>
       </occurrences>
      </subquery>
     </q-children>
    </node>
   </q-nodes>
  </LM>
  <LM id="q-08-12-03_102744">
   <q-nodes>
    <node>
     <node-type>t-node</node-type>
     <q-children>
      <test operator="=">
       <a>functor</a>
       <b>'DPHR'</b>
      </test>
      <test operator="&gt;">
       <a>sons()</a>
       <b>1</b>
      </test>
     </q-children>
    </node>
   </q-nodes>
  </LM>
  <LM id="q-08-12-03_102825">
   <q-nodes>
    <node>
     <node-type>t-node</node-type>
     <q-children>
      <test operator="=">
       <a>functor</a>
       <b>'DPHR'</b>
      </test>
     </q-children>
    </node>
   </q-nodes>
   <output-filters>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>count()</LM>
     </return>
    </LM>
   </output-filters>
  </LM>
  <LM id="q-08-12-03_103027">
   <q-nodes>
    <node>
     <name>n</name>
     <node-type>t-node</node-type>
     <q-children>
      <test operator="=">
       <a>functor</a>
       <b>'DPHR'</b>
      </test>
     </q-children>
    </node>
   </q-nodes>
   <output-filters>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>max(sons($n))</LM>
     </return>
    </LM>
   </output-filters>
  </LM>
  <LM id="q-08-12-03_103036">
   <q-nodes>
    <node>
     <name>n</name>
     <node-type>t-root</node-type>
    </node>
   </q-nodes>
   <output-filters>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>descendants($n)</LM>
     </return>
    </LM>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>max()</LM>
      <LM>min()</LM>
      <LM>avg()</LM>
     </return>
    </LM>
   </output-filters>
  </LM>
  <LM id="q-08-12-03_102908">
   <q-nodes>
    <node>
     <name>t</name>
     <node-type>t-node</node-type>
    </node>
   </q-nodes>
   <output-filters>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>$1</LM>
      <LM>count()</LM>
     </return>
     <group-by>
      <LM>$t.functor</LM>
     </group-by>
     <sort-by>
      <LM>0-$2</LM>
     </sort-by>
    </LM>
   </output-filters>
  </LM>
  <LM id="q-08-12-03_103128">
   <q-nodes>
    <node>
     <name>t</name>
     <node-type>t-node</node-type>
     <q-children>
      <node>
       <name>c</name>
       <node-type>t-node</node-type>
       <relation>
        <user-defined label="coref_gram" />
       </relation>
      </node>
     </q-children>
    </node>
   </q-nodes>
   <output-filters>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>count()</LM>
     </return>
     <group-by>
      <LM>$t</LM>
     </group-by>
    </LM>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>max()</LM>
     </return>
    </LM>
   </output-filters>
  </LM>
  <LM id="q-08-12-03_103151">
   <q-nodes>
    <node>
     <name>n</name>
     <node-type>t-node</node-type>
    </node>
   </q-nodes>
   <output-filters>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>$1</LM>
      <LM>count()</LM>
     </return>
     <group-by>
      <LM>$n.functor</LM>
     </group-by>
     <sort-by>
      <LM>$2</LM>
     </sort-by>
    </LM>
   </output-filters>
  </LM>
  <LM id="q-08-12-03_103209">
   <q-nodes>
    <node>
     <name>p</name>
     <node-type>t-node</node-type>
     <q-children>
      <node>
       <name>c</name>
       <node-type>t-node</node-type>
       <relation>
        <user-defined label="echild" />
       </relation>
      </node>
     </q-children>
    </node>
   </q-nodes>
   <output-filters>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>$p.functor</LM>
      <LM>$c.functor</LM>
     </return>
    </LM>
    <LM>
     <distinct>1</distinct>
     <return>
      <LM>$1</LM>
      <LM>$2</LM>
      <LM>count(over $1,$2)</LM>
      <LM>count(over $1)</LM>
     </return>
    </LM>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>$1</LM>
      <LM>$2</LM>
      <LM>percnt($3 div $4,2)</LM>
     </return>
     <sort-by>
      <LM>$1</LM>
      <LM>0-$3</LM>
     </sort-by>
    </LM>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>$1</LM>
      <LM>$2</LM>
      <LM>$3 &amp; '%'</LM>
     </return>
    </LM>
   </output-filters>
  </LM>
  <LM id="q-08-12-03_103234">
   <q-nodes>
    <node>
     <name>p</name>
     <node-type>t-node</node-type>
     <q-children>
      <node>
       <name>c</name>
       <node-type>t-node</node-type>
       <relation>
        <user-defined label="echild" />
       </relation>
      </node>
     </q-children>
    </node>
   </q-nodes>
   <output-filters>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>$1</LM>
      <LM>$2</LM>
      <LM>ratio(count() over $1)</LM>
     </return>
     <group-by>
      <LM>$p.functor</LM>
      <LM>$c.functor</LM>
     </group-by>
     <sort-by>
      <LM>$1</LM>
      <LM>0-$3</LM>
     </sort-by>
    </LM>
    <LM>
     <distinct>0</distinct>
     <return>
      <LM>$1</LM>
      <LM>$2</LM>
      <LM>percnt($3,2) &amp; '%'</LM>
     </return>
    </LM>
   </output-filters>
  </LM>
 </q-trees>
</tree_query>
