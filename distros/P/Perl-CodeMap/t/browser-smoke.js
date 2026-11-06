'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const data={format:1,name:'Fixture',module:'sample',parser:'lite',scanned_files:3,source:'',rev:'',warnings:[],
 sources:{'lib/Example/A.pm':"package Example::A;\nuse Example::B;\nsub run { return 'ok'; }\n"},
 pkgs:[
  {path:'Example::A',dir:'Example',doc:'',imports:['Example::B'],files:[{path:'lib/Example/A.pm',name:'A.pm',lines:3,funcs:[{n:'run',l:3,s:1,k:'sub',e:true,d:'Run.'}]}]},
  {path:'Example::B',dir:'Example',doc:'',imports:['Example::A'],files:[{path:'lib/Example/B.pm',name:'B.pm',lines:3,funcs:[{n:'_internal',l:3,s:1,k:'sub',e:false,d:''}]}]},
  {path:'Example::C',dir:'Example',doc:'',imports:['Example::B'],files:[{path:'lib/Example/C.pm',name:'C.pm',lines:3,funcs:[{n:'work',l:3,s:1,k:'method',e:true,d:''}]}]},
 ]};
class Element {
 constructor(){this.innerHTML='';this.textContent='';this.dataset={};this.handlers={};this.attrs={};this.value='';this.style={};this.hidden=false;this.disabled=false;this.scrollTop=0;this.classList={toggle(){},add(){},remove(){}};}
 addEventListener(name,cb){this.handlers[name]=cb;}
 setAttribute(k,v){this.attrs[k]=v;}
 getAttribute(k){return this.attrs[k]??null;}
 querySelectorAll(){return [];}
 scrollIntoView(){}
}
const ids={};
for(const id of ['data','heading','stats','legend','map','warning','footer','breadcrumb','home','back','prev','next','page','graph-status','pkgs','files','fns','q','pkgq','public','theme','source-modal','source-title','source-line','source-jump','source-external','source-lines','source-range','source-prev','source-next','source-go','source-close','source-copy'])ids[id]=new Element();
ids.data.textContent=JSON.stringify(data);
const document={getElementById:id=>ids[id]||null,body:new Element(),documentElement:new Element(),addEventListener(){}};
const location={hash:'',href:'https://example.com/example.html',pathname:'/example.html',search:''};
const window={matchMedia:()=>({matches:false}),addEventListener(){},prompt(){}};
vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../lib/Perl/CodeMap/assets/app.js'),'utf8'),{
 document,window,location,history:{replaceState(){}},navigator:{clipboard:{writeText:()=>Promise.resolve()}},
 console,URLSearchParams,encodeURIComponent,
});
assert.match(ids.stats.innerHTML,/3<\/strong><span>packages/);
assert.match(ids.map.innerHTML,/data-from="Example::A"/);
assert.match(ids.map.innerHTML,/data-id="Example::B"/);
assert.match(ids.fns.innerHTML,/href="#source=lib%2FExample%2FA.pm&amp;line=3"/);
assert.match(ids.fns.innerHTML,/view code/);
ids.q.handlers.input({target:{value:'_internal'}});
assert.match(ids.fns.innerHTML,/_internal/);
ids.public.handlers.change({target:{checked:true}});
assert.doesNotMatch(ids.fns.innerHTML,/class="fn"/);
ids.q.handlers.input({target:{value:''}});
ids.public.handlers.change({target:{checked:false}});
ids.pkgq.handlers.input({target:{value:'Example::C'}});
assert.match(ids.pkgs.innerHTML,/Example::C/);
ids.theme.handlers.click();
assert.equal(document.documentElement.getAttribute('data-theme'),'dark');
const el={dataset:{source:'lib/Example/A.pm',line:'3'}};
ids.fns.handlers.click({preventDefault(){},target:{closest:()=>el}});
assert.equal(ids['source-modal'].hidden,false);
assert.match(ids['source-lines'].innerHTML,/source-L3/);
assert.match(ids['source-lines'].innerHTML,/sub run/);
ids['source-close'].handlers.click();
assert.equal(ids['source-modal'].hidden,true);
console.log('DOM smoke checks: graph, search, public filter, theme and embedded source — PASS');
