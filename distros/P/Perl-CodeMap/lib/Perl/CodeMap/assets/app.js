'use strict';
// Self-contained view: graph, package search and source browser. No network IO.
(() => {
  const $ = id => document.getElementById(id);
  const escape = v => String(v ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const fmt = n => Number(n || 0).toLocaleString('en-US');
  const cut = (s,n) => s.length > n ? s.slice(0,n-1)+'…' : s;
  const clamp = (n,lo,hi) => Math.min(hi,Math.max(lo,n));
  try {
    const DATA = JSON.parse($('data').textContent);
    const PACKAGES = DATA.pkgs || [];
    const index = new Map(PACKAGES.map(p => [p.path,p]));
    const categories = new Map(), uniqueFiles = new Map();
    const colors = ['c0','c1','c2','c3','c4','c5','c6'];
    let functions = 0, maxSize = 1;
    for (const pkg of PACKAGES) {
      pkg.fnCount = pkg.files.reduce((sum,f)=>sum+f.funcs.length,0);
      pkg.usedBy = [];
      const root = pkg.path.split('::')[0];
      categories.set(root,(categories.get(root)||0)+1);
      for (const f of pkg.files) {
        uniqueFiles.set(f.path,f.lines);
        for (const fn of f.funcs) {functions++;maxSize=Math.max(maxSize,fn.s);}
      }
    }
    for (const p of PACKAGES) for (const dep of p.imports) {
      const target=index.get(dep);if(target)target.usedBy.push(p.path);
    }
    const groupOrder=[...categories].sort((a,b)=>b[1]-a[1]);
    const palette=new Map(groupOrder.map(([name],i)=>[name,colors[Math.min(i,colors.length-1)]]));
    const shade = name => `var(--${palette.get(name.split('::')[0])||'c6'})`;
    $('stats').innerHTML=[[PACKAGES.length,'packages'],[uniqueFiles.size,'source files'],[functions,'subroutines / methods'],[[...uniqueFiles.values()].reduce((a,b)=>a+b,0),'source lines']]
      .map(([n,label])=>`<div class="stat"><strong>${fmt(n)}</strong><span>${label}</span></div>`).join('');
    $('legend').innerHTML=groupOrder.slice(0,12).map(([name,count])=>`<span><i class="dot" style="background:${shade(name)}"></i>${escape(name)} (${fmt(count)})</span>`).join('');

    let selected=[...PACKAGES].sort((a,b)=>b.fnCount-a.fnCount)[0]?.path || '';
    let selectedFile='', symbolQuery='', packageQuery='', publicOnly=false;
    let scope='', focus='', pageIndex=0, hover='', view=null;
    const LIMIT=32, graph=$('map');
    const within=(name,root)=>!root||name===root||name.startsWith(root+'::');
    const graphLeaf=id=>({id,names:[id],group:false});
    function grouped(root){
      const list=PACKAGES.filter(p=>within(p.path,root));
      if(list.length<=LIMIT)return list.map(p=>graphLeaf(p.path));
      const groups=new Map();
      for(const p of list){
        const relative=root?p.path.slice(root.length).replace(/^::/,''):p.path;
        const id=p.path===root?root:(root?root+'::':'')+relative.split('::')[0];
        if(!groups.has(id))groups.set(id,[]);
        groups.get(id).push(p.path);
      }
      return [...groups].map(([id,names])=>({id,names,group:names.length>1}));
    }
    function state(){
      if(focus){
        const pkg=index.get(focus);
        if(!pkg)return {items:[],edges:[],mode:'focus',top:[],bottom:[],count:0,pages:1};
        const up=[...new Set(pkg.usedBy)].filter(name=>index.has(name)&&name!==focus).sort();
        const down=[...new Set(pkg.imports)].filter(name=>index.has(name)&&name!==focus).sort();
        const already=new Set([focus]);
        const top=up.filter(name=>!already.has(name)).slice(0,6);top.forEach(name=>already.add(name));
        const bottom=down.filter(name=>!already.has(name)).slice(0,6);bottom.forEach(name=>already.add(name));
        return {mode:'focus',items:[...top.map(graphLeaf),graphLeaf(focus),...bottom.map(graphLeaf)],
          edges:[...top.map(from=>({from,to:focus})),...bottom.map(to=>({from:focus,to}))],
          top,bottom,totalUp:up.length,totalDown:down.length,count:1+top.length+bottom.length,pages:1};
      }
      const all=grouped(scope).sort((a,b)=>b.names.length-a.names.length||a.id.localeCompare(b.id));
      const pages=Math.max(1,Math.ceil(all.length/LIMIT));
      pageIndex=clamp(pageIndex,0,pages-1);
      const items=all.slice(pageIndex*LIMIT,(pageIndex+1)*LIMIT),members=new Map();
      for(const item of items) for(const id of item.names) members.set(id,item.id);
      const links=new Map();
      for(const p of PACKAGES){
        const from=members.get(p.path);if(!from)continue;
        for(const dep of p.imports){
          const to=members.get(dep);if(!to||to===from)continue;
          const key=from+'\0'+to;
          if(!links.has(key))links.set(key,{from,to});
        }
      }
      return {mode:'scope',items,edges:[...links.values()],count:all.length,pages};
    }
    function topology(items,edges){
      const graph=new Map(items.map(({id})=>[id,[]]));
      for(const {from,to} of edges) if(graph.has(from)&&graph.has(to))graph.get(from).push(to);
      const indexes=new Map(),low=new Map(),stack=[],active=new Set(),components=[];
      let counter=0;
      function visit(id){
        indexes.set(id,counter);low.set(id,counter++);stack.push(id);active.add(id);
        for(const to of graph.get(id)){
          if(!indexes.has(to)){visit(to);low.set(id,Math.min(low.get(id),low.get(to)));}
          else if(active.has(to))low.set(id,Math.min(low.get(id),indexes.get(to)));
        }
        if(low.get(id)===indexes.get(id)){
          const component=[];let node;
          do{node=stack.pop();active.delete(node);component.push(node);}while(node!==id);
          components.push(component.sort());
        }
      }
      [...graph.keys()].forEach(id=>{if(!indexes.has(id))visit(id);});
      const part=new Map(),dag=new Map();
      components.forEach((nodes,i)=>{dag.set(i,new Set());nodes.forEach(node=>part.set(node,i));});
      for(const e of edges){const a=part.get(e.from),b=part.get(e.to);if(a!==b)dag.get(a).add(b);}
      const depths=new Map();
      function depth(id){
        if(depths.has(id))return depths.get(id);
        const level=1+Math.max(-1,...[...dag.get(id)].map(depth));
        depths.set(id,level);return level;
      }
      components.forEach((_,i)=>depth(i));
      const layers=[];
      for(const id of graph.keys()){const d=depths.get(part.get(id));(layers[d] ||= []).push(id);}
      for(let round=0;round<3;round++)for(let d=1;d<layers.length;d++){
        const prev=new Map(layers[d-1].map((name,i)=>[name,i]));
        const rank=name=>{
          const hits=graph.get(name).filter(child=>prev.has(child)).map(child=>prev.get(child));
          return hits.length?hits.reduce((a,b)=>a+b,0)/hits.length:1000;
        };
        layers[d].sort((a,b)=>rank(a)-rank(b)||a.localeCompare(b));
      }
      return {layers,part};
    }
    function positions(data){
      const w=171,h=38,g=12,rh=77,pad=40,positions=new Map(),labels=[];
      if(data.mode==='focus'){
        const maxWidth=Math.max(data.top.length,data.bottom.length,1);
        const width=Math.max(1020,80+maxWidth*(w+g)-g),center=width/2;
        function set(names,y){let x=center-(names.length*(w+g)-g)/2;
          for(const name of names){positions.set(name,{x,y,w,h,cx:x+w/2});x+=w+g;}}
        set(data.top,46);set([focus],153);set(data.bottom,266);
        return {positions,width,height:347,part:new Map(),labels:[{name:'used by',y:30},{name:'selected',y:137},{name:'uses',y:251}]};
      }
      const {layers,part}=topology(data.items,data.edges);
      const packed=[];
      for(let d=0;d<layers.length;d++)for(let i=0;i<layers[d].length;i+=6){packed.push({names:layers[d].slice(i,i+6),d,i});}
      const columns=Math.max(1,...packed.map(row=>row.names.length));
      const width=Math.max(1020,80+columns*(w+g)-g),height=Math.max(150,80+packed.length*rh);
      packed.forEach((row,i)=>{
        const rowWidth=row.names.length*(w+g)-g,y=height-pad-(i+1)*rh+16;
        let x=(width-rowWidth)/2;
        if(row.i===0)labels.push({name:row.d===0?'foundations':row.d===layers.length-1?'top':`layer ${row.d+1}`,y:y+24});
        for(const name of row.names){positions.set(name,{x,y,w,h,cx:x+w/2});x+=w+g;}
      });
      return {positions,width,height,part,labels};
    }
    function highlight(id){
      graph.querySelectorAll('.edge').forEach(el=>{
        const uses=!!id&&el.dataset.from===id,usedby=!!id&&el.dataset.to===id;
        el.classList.toggle('uses',uses);el.classList.toggle('usedby',usedby);
        el.classList.toggle('faded',!!id&&!uses&&!usedby);
      });
      graph.querySelectorAll('.node').forEach(el=>{
        const related=!!id&&view?.edges.some(e=>(e.from===id&&e.to===el.dataset.id)||(e.to===id&&e.from===el.dataset.id));
        el.classList.toggle('selected',id===el.dataset.id);
        el.classList.toggle('dim',!!id&&id!==el.dataset.id&&!related);
      });
    }
    function renderGraph(){
      view=state();const {positions,width,height,part,labels}=positionsForView(view);
      graph.setAttribute('viewBox',`0 0 ${width} ${height}`);
      graph.style.width=width+'px';graph.style.height=height+'px';
      let paths='',nodes='';
      for(const e of view.edges){
        const a=positions.get(e.from),b=positions.get(e.to);if(!a||!b)continue;
        const same=part.get(e.from)!==undefined&&part.get(e.from)===part.get(e.to);
        const y1=a.y+a.h,y2=b.y,mid=(y1+y2)/2;
        const curve=same||y2<=y1
          ? `M${a.cx},${a.y+a.h/2} C${a.cx+34},${a.y-20} ${b.cx-34},${b.y-20} ${b.cx},${b.y+b.h/2}`
          : `M${a.cx},${y1} C${a.cx},${mid} ${b.cx},${mid} ${b.cx},${y2}`;
        paths+=`<path class="edge${same?' cycle':''}" data-from="${escape(e.from)}" data-to="${escape(e.to)}" d="${curve}"/>`;
      }
      for(const item of view.items){
        const p=positions.get(item.id);if(!p)continue;
        const label=scope&&item.id.startsWith(scope+'::')?item.id.slice(scope.length+2):item.id;
        const meta=item.group?`${fmt(item.names.length)} packages · open`:`${fmt(index.get(item.id)?.fnCount)} subroutines`;
        nodes+=`<g class="node" role="button" tabindex="0" data-id="${escape(item.id)}" aria-label="${escape(item.id)} — ${escape(meta)}">
          <rect class="frame" x="${p.x}" y="${p.y}" width="${p.w}" height="${p.h}" rx="5" style="stroke:${shade(item.id)}"/>
          <rect x="${p.x}" y="${p.y}" width="4" height="${p.h}" rx="2" style="fill:${shade(item.id)}" stroke="none"/>
          <text class="node-name" x="${p.cx}" y="${p.y+16}" text-anchor="middle">${escape(cut(label,25))}</text>
          <text class="node-sub" x="${p.cx}" y="${p.y+30}" text-anchor="middle">${escape(meta)}</text>
          <title>${escape(item.id)}</title></g>`;
      }
      graph.innerHTML=labels.map(l=>`<text class="layer-label" x="8" y="${l.y}">${escape(l.name)}</text>`).join('')+
        `<g>${paths}</g><g>${nodes}</g>`;
      $('breadcrumb').textContent=focus?`Dependencies / ${focus}`:scope?scope.replace(/::/g,' / '):'Namespace overview';
      $('back').disabled=!focus&&!scope;$('prev').disabled=!!focus||pageIndex===0;$('next').disabled=!!focus||pageIndex>=view.pages-1;
      $('page').textContent=focus?'':`Page ${pageIndex+1} of ${view.pages}`;
      $('graph-status').textContent=focus?
        `Used by ${view.totalUp} local packages (showing ${view.top.length}); uses ${view.totalDown} (showing ${view.bottom.length}). Select a node to move focus.`:
        `${fmt(PACKAGES.filter(p=>within(p.path,scope)).length)} packages in scope · ${view.count} entries · ${view.edges.length} visible local dependency links.`;
      highlight(focus||hover);
    }
    const positionsForView=positions;
    function graphSelect(name){
      const item=view.items.find(i=>i.id===name);
      if(item?.group){scope=name;focus='';pageIndex=0;renderGraph();return;}
      if(index.has(name))selectPackage(name,true);
    }
    function back(){
      if(focus){focus='';pageIndex=0;renderGraph();return;}
      if(scope){scope=scope.includes('::')?scope.slice(0,scope.lastIndexOf('::')):'';pageIndex=0;renderGraph();}
    }
    graph.addEventListener('click',e=>{const el=e.target.closest('[data-id]');if(el)graphSelect(el.dataset.id);});
    graph.addEventListener('keydown',e=>{const el=e.target.closest('[data-id]');if(el&&(e.key==='Enter'||e.key===' ')){e.preventDefault();graphSelect(el.dataset.id);}});
    graph.addEventListener('pointerover',e=>{const el=e.target.closest('[data-id]');if(el){hover=el.dataset.id;highlight(hover);}});
    graph.addEventListener('pointerleave',()=>{hover='';highlight(focus);});
    $('home').addEventListener('click',()=>{scope='';focus='';pageIndex=0;renderGraph();});
    $('back').addEventListener('click',back);
    $('prev').addEventListener('click',()=>{pageIndex--;renderGraph();});
    $('next').addEventListener('click',()=>{pageIndex++;renderGraph();});

    // Source code is embedded once per file. Offline Perl highlighting is by Prism.
    const sources=DATA.sources||{};
    const hash=(path,line)=>`#source=${encodeURIComponent(path)}&line=${Math.max(1,Number(line)||1)}`;
    const remote=(path,line)=>{
      const base=DATA.source||'';
      if(!/^https?:\/\//i.test(base))return '';
      return base.replace(/\/?$/,'/')+path.split('/').map(encodeURIComponent).join('/')+`#L${Number(line)||1}`;
    };
    const modal=$('source-modal');let sourcePath='',sourceLine=1,firstLine=1;
    function colorize(text){
      const language=window.Prism?.languages?.perl;
      if(!language)return text.split('\n').map(escape);
      const div=document.createElement('div');
      div.innerHTML=window.Prism.highlight(text,language,'perl');
      function concatenate(children){
        const result=[''];
        for(const node of children){const bits=splitNode(node);result[result.length-1]+=bits[0];for(let i=1;i<bits.length;i++)result.push(bits[i]);}
        return result;
      }
      function splitNode(node){
        if(node.nodeType===3)return (node.nodeValue||'').split('\n').map(escape);
        const bits=concatenate(node.childNodes);
        if(node.nodeType!==1)return bits;
        return bits.map(html=>`<span class="${escape(node.className||'')}">${html}</span>`);
      }
      return concatenate(div.childNodes);
    }
    function paintSource(path,line,start){
      sourcePath=path;sourceLine=Math.max(1,Number(line)||1);
      $('source-title').textContent=path;$('source-line').textContent=`Line ${sourceLine}`;$('source-jump').value=sourceLine;
      const url=remote(path,sourceLine);$('source-external').hidden=!url;if(url)$('source-external').href=url;
      if(typeof sources[path]!=='string'){
        $('source-lines').innerHTML='<p class="empty">Source was not embedded in this export. Re-run with <code>--embed-source</code> or use <code>--from-json … --root ORIGINAL_SOURCE</code>.</p>';
        $('source-range').textContent='Source unavailable';$('source-prev').disabled=true;$('source-next').disabled=true;
        return;
      }
      const lines=sources[path].split(/\r?\n/),total=lines.length;
      firstLine=clamp(start||sourceLine-65,1,Math.max(1,total));
      const last=Math.min(total,firstLine+159);
      const highlighted=colorize(lines.slice(firstLine-1,last).join('\n'));
      let html='';
      for(let at=firstLine;at<=last;at++){
        html+=`<div class="source-row${at===sourceLine?' target':''}" id="source-L${at}">`+
          `<a href="${escape(hash(path,at))}" class="line-no" data-line="${at}">${at}</a>`+
          `<span class="source-text">${highlighted[at-firstLine]||' '}</span></div>`;
      }
      $('source-lines').innerHTML=html;
      $('source-range').textContent=`Lines ${fmt(firstLine)}–${fmt(last)} of ${fmt(total)}`;
      $('source-prev').disabled=firstLine<=1;$('source-next').disabled=last>=total;
      const target=$(`source-L${sourceLine}`);if(target)target.scrollIntoView({block:'center'});
    }
    function openSource(path,line){
      modal.hidden=false;document.body.style.overflow='hidden';
      try{location.hash=hash(path,line);}catch(_){}
      paintSource(path,line);
    }
    function closeSource(){
      modal.hidden=true;document.body.style.overflow='';
      if(location.hash.startsWith('#source=')){
        try{history.replaceState(null,'',location.pathname+location.search);}catch(_){location.hash='';}
      }
    }
    $('source-close').addEventListener('click',closeSource);
    modal.addEventListener('click',e=>{if(e.target===modal)closeSource();});
    document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!modal.hidden)closeSource();});
    $('source-prev').addEventListener('click',()=>paintSource(sourcePath,sourceLine,Math.max(1,firstLine-160)));
    $('source-next').addEventListener('click',()=>paintSource(sourcePath,sourceLine,firstLine+160));
    $('source-go').addEventListener('click',()=>openSource(sourcePath,$('source-jump').value));
    $('source-jump').addEventListener('keydown',e=>{if(e.key==='Enter')openSource(sourcePath,e.target.value);});
    $('source-copy').addEventListener('click',()=>{
      const url=location.href;
      if(navigator.clipboard?.writeText)navigator.clipboard.writeText(url).catch(()=>window.prompt('Copy link:',url));
      else window.prompt('Copy link:',url);
    });
    $('source-lines').addEventListener('click',e=>{
      const el=e.target.closest('[data-line]');if(el){e.preventDefault();openSource(sourcePath,el.dataset.line);}
    });
    window.addEventListener('hashchange',()=>{
      if(!location.hash.startsWith('#source='))return;
      const params=new URLSearchParams(location.hash.slice(1));
      const path=params.get('source');if(uniqueFiles.has(path))openSource(path,params.get('line'));
    });

    function packageList(){
      const q=(packageQuery||symbolQuery).toLowerCase();
      const matches=PACKAGES.filter(p=>!q||p.path.toLowerCase().includes(q)).sort((a,b)=>b.fnCount-a.fnCount||a.path.localeCompare(b.path));
      $('pkgs').innerHTML=`<div class="coltitle">${fmt(matches.length)} packages${matches.length>180?' · first 180':''}</div>`+
        matches.slice(0,180).map(p=>`<button class="item${p.path===selected?' selected':''}" type="button" data-pkg="${escape(p.path)}"><i class="dot" style="background:${shade(p.path)}"></i><span class="label">${escape(p.path)}</span><span class="num">${fmt(p.fnCount)}</span></button>`).join('')+
        (!matches.length?'<p class="empty">No matching package names.</p>':'');
    }
    const pkgLinks=items=>items.length?items.slice(0,30).map(n=>`<a href="#" data-nav="${escape(n)}">${escape(n)}</a>`).join(', ')+(items.length>30?` · +${items.length-30} more`:''):'none';
    function fileList(){
      const p=index.get(selected);if(!p)return;
      $('files').innerHTML=`<div class="coltitle">Package details</div><div class="details"><strong>${escape(p.path)}</strong>`+
        (p.doc?`<p>${escape(p.doc)}</p>`:'')+`<div class="relation">Uses: ${pkgLinks(p.imports)}</div><div class="relation">Used by: ${pkgLinks(p.usedBy)}</div></div>`+
        `<button class="item${selectedFile===''?' selected':''}" type="button" data-file=""><span class="label">All files</span><span class="num">${p.fnCount}</span></button>`+
        p.files.map(f=>`<button type="button" data-file="${escape(f.path)}" class="item${selectedFile===f.path?' selected':''}"><span class="label">${escape(f.path)}</span><span class="num">${f.funcs.length}</span></button>`).join('');
    }
    function fnRow(fn,p,f,showPackage){
      const link=escape(hash(f.path,fn.l));
      return `<div class="fn"><div class="signature"><span class="kind">${escape(fn.k||'sub')}</span> `+
        `<a class="name" href="${link}" data-source="${escape(f.path)}" data-line="${fn.l}">${escape(fn.n)}</a>`+
        (showPackage?` <span style="color:var(--muted)">${escape(p.path)} / ${escape(f.path)}</span>`:'')+`</div>`+
        `<div class="meta">${fmt(fn.s)} lines · <a href="${link}" data-source="${escape(f.path)}" data-line="${fn.l}">view code</a></div>`+
        (fn.d?`<div class="doc">${escape(fn.d)}</div>`:'')+
        `<div class="bar" style="width:${Math.max(3,Math.min(100,100*fn.s/Math.min(200,maxSize)))}%"></div></div>`;
    }
    function functionList(){
      const okay=(fn,p,f)=>(!publicOnly||fn.e)&&(!symbolQuery||(fn.n+' '+fn.d+' '+p.path+' '+f.path+' '+fn.k).toLowerCase().includes(symbolQuery));
      let html='',count=0;
      if(symbolQuery){
        for(const p of PACKAGES)for(const f of p.files)for(const fn of f.funcs){
          if(!okay(fn,p,f))continue;
          if(++count<=300)html+=fnRow(fn,p,f,true);
        }
        $('fns').innerHTML=`<div class="coltitle">${fmt(count)} matches${count>300?' · first 300':''}</div>`+(html||'<p class="empty">No matches.</p>');
        return;
      }
      const p=index.get(selected);if(!p)return;
      for(const file of p.files){
        if(selectedFile&&selectedFile!==file.path)continue;
        html+=`<div class="coltitle file-title" data-source="${escape(file.path)}" data-line="1">${escape(file.path)} · ${fmt(file.lines)} lines · view file</div>`;
        for(const fn of file.funcs)if(okay(fn,p,file)){count++;html+=fnRow(fn,p,file,false);}
      }
      $('fns').innerHTML=html||'<p class="empty">No subroutine declarations in this selection.</p>';
    }
    function selectPackage(name,refocus){
      if(!index.has(name))return;
      selected=name;selectedFile='';packageList();fileList();functionList();
      if(refocus){scope='';focus=name;pageIndex=0;renderGraph();}
      $('files').scrollTop=0;$('fns').scrollTop=0;
    }
    $('pkgs').addEventListener('click',e=>{const el=e.target.closest('[data-pkg]');if(el)selectPackage(el.dataset.pkg,true);});
    $('files').addEventListener('click',e=>{
      const nav=e.target.closest('[data-nav]');if(nav){e.preventDefault();selectPackage(nav.dataset.nav,true);return;}
      const el=e.target.closest('[data-file]');if(el){selectedFile=el.dataset.file;fileList();functionList();}
    });
    $('fns').addEventListener('click',e=>{const el=e.target.closest('[data-source]');if(el){e.preventDefault();openSource(el.dataset.source,el.dataset.line||1);}});
    $('q').addEventListener('input',e=>{symbolQuery=e.target.value.trim().toLowerCase();packageList();functionList();});
    $('pkgq').addEventListener('input',e=>{packageQuery=e.target.value.trim().toLowerCase();packageList();});
    $('public').addEventListener('change',e=>{publicOnly=e.target.checked;functionList();});
    $('theme').addEventListener('click',()=>{
      const cur=document.documentElement.getAttribute('data-theme');
      const dark=window.matchMedia('(prefers-color-scheme:dark)').matches;
      document.documentElement.setAttribute('data-theme',cur==='dark'?'light':cur==='light'?'dark':dark?'light':'dark');
    });
    if(DATA.parser==='lite'||(DATA.warnings||[]).length){
      $('warning').hidden=false;
      $('warning').textContent=(DATA.parser==='lite'?'Limited parser mode: install PPI for more accurate Perl analysis. ':'')+
        `${(DATA.warnings||[]).length} analysis/embedding warnings. The graph includes statically recognizable local dependencies only.`;
    }
    $('footer').textContent=`${fmt(DATA.scanned_files)} source files analyzed using ${DATA.parser||'unknown'} · `+
      `${fmt(Object.keys(sources).length)} files embedded for offline viewing. Embedded reports may contain sensitive project code.`;
    if(PACKAGES.length){renderGraph();selectPackage(selected,false);if(location.hash.startsWith('#source=')){
      const params=new URLSearchParams(location.hash.slice(1));if(uniqueFiles.has(params.get('source')))openSource(params.get('source'),params.get('line'));
    }}else $('graph-status').textContent='No Perl packages were found in this report.';
  } catch(error){
    console.error('CodeMap initialization failed',error);
    $('warning').hidden=false;$('warning').textContent='Unable to render report: '+String(error?.message||error);
  }
})();
