#include <string>
#include <cstring>
#include <iostream>
#include <sstream>
#include <vector>
#include <list>
#include <set>
#include <regex>
#include <algorithm>
#include <stdexcept>
#include <thread>

#include "algo.h"

using namespace std;

#define BUFFER_LEN 8192

#define INIT_CLASS \
this->matchStrArr = new vector<string>();\
this->catArr = new vector<string>();\
this->arrMutex = new std::mutex();\
this->caseInsensitive = caseInsensitive;\
this->tac = tac;\
this->readerStatus = new int;\
*(this->readerStatus) = 0;\
this->syncStatus = new int;\
*(this->syncStatus) = 0;\
this->exitSign = new int;\
*(this->exitSign) = 0;\
this->maxLen = new int;\
this->headerArr = new vector<string>();\
this->markList = new vector<unsigned short>();\
this->headerMutex = new std::mutex();\
this->headerLines = headerLines;\
*(this->maxLen) = 0;

/*构造函数
  由于需要使用多线程, 很多成员变量都使用堆分配*/
AlgoCpp::AlgoCpp(int tac, int caseInsensitive, int headerLines) {
  INIT_CLASS;
}

/*带有nth选项参数的构造函数*/
AlgoCpp::AlgoCpp(int tac, int caseInsensitive, int headerLines, int nth, char* delim, AV* filter){
  INIT_CLASS;

  this->nth = nth;
  if (this->nth == 1) {
    //delim分隔符, filter是nth选项选择的列表vector
    this->delim = new string(delim);
    this->filter = new vector<int>;
    //将输入的perl array数组装载到vector中
    int s = av_top_index(filter) + 1;
    for(int i=0; i< s; i++) {
      SV** a = av_fetch(filter, i, 1);
      int f = SvIV(*a);
      this->filter->push_back(f);
    }
  }
}

/*析构函数, 释放各种资源*/
AlgoCpp::~AlgoCpp(){
  delete this->matchStrArr;
  delete this->catArr;
  delete this->arrMutex;
  delete this->headerArr;
  delete this->headerMutex;
  delete this->readerStatus;
  delete this->exitSign;
  delete this->markList;
  if(this->nth == 1) {
    delete this->delim;
    delete this->filter;
  }
}

/*输入线程执行函数*/
void AlgoCpp::getInput(input_task_t task) {
  //输入缓冲区
  char charbuf[BUFFER_LEN];
  // stringbuf buf;

  size_t readChars;
  bool cont=false;
  int inputLines = 0;
  list<string> strList;
  //从文件句柄读入缓冲区
  while((readChars = PerlIO_read(task.fileH, charbuf, BUFFER_LEN)) >0){
    // buf.sputn(charbuf, readChars);
    // istream in(&buf);
    
    /*由缓冲区构建字符串, 并以此建立istringstream*/
    string inStr(charbuf, readChars);
    istringstream in(inStr);
    //调用getline方法
    string out;
    while(getline(in, out)){
      if(cont) {//若是上次循环遗留的部分字符串
        out = strList.front() + out;
        strList.pop_front();
        cont = false;
      }
      //将getline获得的字符串, 加入vector
      strList.push_back(out);
    }

    //最后一行若不以"\n"结尾, 着为遗留部分
    if(charbuf[readChars-1] != '\n') cont = true;
    //将stringList中的整行加载到列表中
    int outSize;
    if(cont) outSize = strList.size() - 1;
    else outSize = strList.size();
    for(int i=0; i<outSize; i++) {
      if(inputLines < task.headerLines){//若有headerLines配置, 首先加载
        try{
          std::lock_guard<std::mutex> lck(*(task.headerMutex));
          task.headerArr->push_back(strList.front());
        }catch(std::logic_error&){
          cout << "[exception caught]\n";
        }
      }else{//正文列表加载到catArr
        try{
          std::lock_guard<std::mutex> lck(*(task.mtx));
          task.catArr->push_back(strList.front());
          if(strList.front().size() > (*(task.maxLen))) (*(task.maxLen)) = strList.front().size();
          task.markList->push_back(0);
        }catch(std::logic_error&){
          cout << "[exception caught]\n";
        }
      }
      strList.pop_front();
      inputLines ++;
    }

    if((*task.exitSign) == 1) break;
  }
  (*(task.readerStatus)) = 1;
}

#ifdef USE_PCRE_REGEX
/*use pcre library*/
/*将字符串按照分割符切分, 并形成token+delim的数组*/
// pcre1
// vector<string> AlgoCpp::stringSplit(const string& seq, const string delim) {
//     Pcre reg(delim, "g");
//
//     int off = 0;
//     vector<int> loc;
//     //循环取得所有正则匹配的起始和结束位置
//     while(reg.search(seq, off) == true) {
//       loc.push_back(reg.get_match_start());
//       loc.push_back(reg.get_match_end()+1);
//       off = reg.get_match_end() + 1;
//     }
//
//     //按照起始和结束位置, 将token+delim拼装
//     vector<string> tokens;
//     if(loc.size() > 0) {
//       int s = 0;
//       for(int i=0; i<loc.size()/2; i++) {
//         string t = seq.substr(s, loc[i*2]-s);
//         string d = seq.substr(loc[i*2], loc[i*2+1]-loc[i*2]);
//         //拼装好的字段加入数组
//         tokens.push_back(t+d);
//         s = loc[i*2+1];
//       }
//       if (loc.back() < seq.size()) tokens.push_back(seq.substr(loc.back(), seq.size() - loc.back()));
//     }else{
//       tokens.push_back(seq);
//     }
//     return tokens;
// }
vector<string> AlgoCpp::stringSplit(const string& seq, jp::Regex& reg) {
  // jp::VecNum vec_num;   //Vector to store numbered substring vectors.
  jpcre2::VecOff vec_start;
  jpcre2::VecOff vec_end;
  jp::RegexMatch rm;
  rm.setRegexObject(&reg)                        //set associated Regex object
    .setMatchStartOffsetVector(&vec_start)
    .setMatchEndOffsetVector(&vec_end);
    // .setNumberedSubstringVector(&vec_num);
  size_t matched = rm.setSubject(seq).addModifier("g").match();                                   //Now perform the match

  vector<string> tokens;
  int pos = 0;
  if(matched){
    for(size_t i=0;i<vec_start.size();++i){
      // int index = seq.find(vec_num[i][0], pos);
      string t = seq.substr(pos, vec_start[i] - pos);
      string d = seq.substr(vec_start[i], vec_end[i] - vec_start[i]);
      tokens.push_back(t+d);
      pos = vec_end[i];
    }
  }
  if (pos < seq.size()) tokens.push_back(seq.substr(pos, seq.size() - pos));
  // for(auto it=tokens.cbegin(); it !=tokens.cend(); ++it )
  //   DBGprint("token=%s\n", (*it).c_str());
  return tokens;
}

#else
/*use STL Regex library*/
//使用STL库实现的stringSplit函数, 性能差于pcre库, 但无需使用外部库
vector<string> AlgoCpp::stringSplit(const string& str, regex& reg) {
    // regex reg(delim);
    //获得所有tokens
    vector<string> elems(sregex_token_iterator(str.begin(), str.end(), reg, -1),
                                   sregex_token_iterator());
    //获得所有delims
    vector<string> elemsDelim(sregex_token_iterator(str.begin(), str.end(), reg, 0),
                                   sregex_token_iterator());
    //拼装
    vector<string> joinvec;
    for(int i=0; i<elemsDelim.size(); i++) joinvec.push_back(elems[i]+elemsDelim[i]);
    if (elems.size() > elemsDelim.size()) joinvec.push_back(elems.back());
    return joinvec;
}
#endif

/*同步catArr和matchStrArr*/
//catArr用于保存原始字符串, 用于显示模块调用
//matchStrArr则负责保存所有被匹配字符串, 按照nth选项和caseInsensitive选项进行预处理
//syncMatchArr方法与getInput方法为多线程并行执行
//对于catArr的操作需要使用信号灯加锁
void AlgoCpp::syncMatchArr(vector<string>* catArr, vector<string>* matchStrArr, std::mutex* mtx, int* readerStatus, int* syncStatus, int* exitSign, int caseInsensitive){
    mtx->lock();
    int catSize = catArr->size();
    mtx->unlock();

    while((*readerStatus) == 0) {
      mtx->lock();
      for(int i=matchStrArr->size(); i<catSize; i++) {
        string l = catArr->at(i);
        //caseInsensitive选项, 则全部转化为小写字符
        if (caseInsensitive == 1) l = lowercase(l);
        matchStrArr->push_back(l);
      }
      catSize = catArr->size();
      mtx->unlock();

      if ((*exitSign) == 1) break;
    }

    for(int i=matchStrArr->size(); i<catArr->size(); i++) {
      if ((*exitSign) == 1) break;

      string l = catArr->at(i);
      if (caseInsensitive == 1) l = lowercase(l);
      matchStrArr->push_back(l);
    }
    (*syncStatus) = 1;
}

#define COPY_TO_MATCH_ARR(reg,fset) \
vector<string> elems = stringSplit(catArr->at(i), reg);\
string out = "";\
for(int i=0; i<elems.size(); i++) {\
  if(fset.count(i) > 0) {\
    out = out + elems.at(i);\
  }else continue;\
}\
if (caseInsensitive == 1) out = lowercase(out);\
matchStrArr->push_back(out);

//带nth选项的同步方法, 首先将catArr中的字符串按照delim正则条件切分
//然后按照filter列表中的筛选项将列表元素加载到matchStrArr
//调用宏COPY_TO_MATCH_ARR
void AlgoCpp::syncMatchArrNTH(vector<string>* catArr, vector<string>* matchStrArr, std::mutex* mtx, int* readerStatus, int* syncStatus, int* exitSign, int caseInsensitive, string* delim, vector<int>* filter){
    set<int> fset;
    for(auto it=filter->cbegin(); it!=filter->cend(); ++it) fset.insert(*it);

#ifdef USE_PCRE_REGEX
    jp::Regex reg (*delim);
#else
    regex reg(*delim);
#endif

    mtx->lock();
    int catSize = catArr->size();
    mtx->unlock();

    while((*readerStatus) == 0) {
      mtx->lock();
      for(int i=matchStrArr->size(); i<catSize; i++) {
        COPY_TO_MATCH_ARR(reg,fset)
      }
      catSize = catArr->size();
      mtx->unlock();

      if ((*exitSign) == 1) break;
    }
    for(int i=matchStrArr->size(); i<catArr->size(); i++) {
      if ((*exitSign) == 1) break;

      COPY_TO_MATCH_ARR(reg,fset)
    }
    (*syncStatus) = 1;
}

/*异步读文件方法, 生成两个线程*/
//分别执行getInput和synMatchArr
void AlgoCpp::asynRead(PerlIO* fileH){
    input_task_t task;
    task.fileH = fileH;
    task.catArr = this->catArr;
    task.mtx = this->arrMutex;
    task.readerStatus = this->readerStatus;
    task.exitSign = this->exitSign;
    task.maxLen = this->maxLen;
    task.headerLines = this->headerLines;
    task.headerArr = this->headerArr;
    task.headerMutex = this->headerMutex;
    task.markList = this->markList;
    // std::thread t(getInput, fileH, this->catArr, this->arrMutex, this->readerStatus, this->maxLen, this->headerLines, this->headerArr, this->headerMutex);
    std::thread t(getInput, task);
    t.detach();
    if (this->nth == 0) {
      std::thread s(syncMatchArr, this->catArr, this->matchStrArr, this->arrMutex, this->readerStatus, this->syncStatus, this->exitSign, this->caseInsensitive);
      s.detach();
    }else{
      std::thread s(syncMatchArrNTH, this->catArr, this->matchStrArr, this->arrMutex, this->readerStatus, this->syncStatus, this->exitSign, this->caseInsensitive, this->delim, this->filter);

#ifdef USE_PCRE_REGEX
      s.detach();
#else
      //STL 库在并发时存在内存泄露, 需要join同步执行
      s.join();
#endif
    }
}

/*catArr锁*/
void AlgoCpp::asynLock(){
  this->arrMutex->lock();
}
/*解锁*/
void AlgoCpp::asynUnLock(){
  this->arrMutex->unlock();
}
/*获取是否读完的状态*/
int AlgoCpp::getReaderStatus() {
   if (*(this->readerStatus) == 1 && *(this->syncStatus) == 1) return 1;
   else return 0;
}
void AlgoCpp::sendExitSign() {
  *(this->exitSign) = 1;
}

/*根据行号获取原字符串, 用于显示, 转化为perl的字符串*/
SV* AlgoCpp::getStr(int index) {
  std::lock_guard<std::mutex> lck(*(this->arrMutex));
  return newSVpvn(this->catArr->at(index).c_str(), this->catArr->at(index).size());
}
/*获取显示列表的数量*/
int AlgoCpp::getCatArraySize() {
  std::lock_guard<std::mutex> lck(*(this->arrMutex));
  return this->catArr->size();
}
/*设置选择标记*/
void AlgoCpp::setMarkLabel(int id){
  std::lock_guard<std::mutex> lck(*(this->arrMutex));
  this->markList->at(id) = 1;
}
/*将所有列表项设置选择标记*/
void AlgoCpp::setAllMarkLabel(){
  std::lock_guard<std::mutex> lck(*(this->arrMutex));
  for(int id=0; id<this->markList->size(); id++) this->markList->at(id) = 1;
}
/*解除列表项的选择标记*/
void AlgoCpp::unSetMarkLabel(int id){
  std::lock_guard<std::mutex> lck(*(this->arrMutex));
  this->markList->at(id) = 0;
}
/*解除所有列表项的选择标记*/
void AlgoCpp::unSetAllMarkLabel(){
  std::lock_guard<std::mutex> lck(*(this->arrMutex));
  for(int id=0; id<this->markList->size(); id++) this->markList->at(id) = 0;
}
/*切换选择项的选择标记, 若选中--->非选中, 或, 非选中--->选中*/ 
void AlgoCpp::toggleMarkLabel(int id){
  std::lock_guard<std::mutex> lck(*(this->arrMutex));
  this->markList->at(id) = (this->markList->at(id) + 1)%2;
}
/*切换所有列表项的选择标记*/
void AlgoCpp::toggleAllMarkLabel(){
  std::lock_guard<std::mutex> lck(*(this->arrMutex));
  for(int id=0; id<this->markList->size(); id++) this->markList->at(id) = (this->markList->at(id) + 1)%2;
}
/*获取所有带有选择标记的列表项子集*/
AV* AlgoCpp::getMarkedStr() {
  AV* ret = newAV();
  std::lock_guard<std::mutex> lck(*(this->headerMutex));
  for(int i=0; i<this->markList->size(); i++)
    if (this->markList->at(i) == 1) 
      av_push(ret, newSVpvn(this->catArr->at(i).c_str(), this->catArr->at(i).size()));
  return ret;
}
/*取得列表项的选择标记*/
int AlgoCpp::getMarkLable(int id) {
  std::lock_guard<std::mutex> lck(*(this->headerMutex));
  return this->markList->at(id);
}
/*标记为选中的列表项数量*/
int AlgoCpp::getMarkedCount() {
  std::lock_guard<std::mutex> lck(*(this->headerMutex));
  //使用count_if算法
  return count_if(this->markList->cbegin(), this->markList->cend(), [](int x)->bool{return x == 1;});
}

/*同步的读方法*/
void AlgoCpp::read(AV* perlArr) {
  int rows = av_top_index(perlArr) + 1;
  for(int i=0; i<rows; i++) {
    SV** a = av_fetch(perlArr, i, 1);
    const char * src = SvPVbyte_nolen(*a);
    char* buff = new char[strlen(src) + 1];
    strcpy(buff, src);
    string s =  buff;
    if(i < this->headerLines) this->headerArr->push_back(s); 
    else {
      this->catArr->push_back(s); 
      this->markList->push_back(0);
    }
    delete[] buff;
  }

  if (this->nth == 0) {
    for(int i=this->matchStrArr->size(); i<this->catArr->size(); i++) {
      string l = this->catArr->at(i);
      if (this->caseInsensitive == 1) l = lowercase(l);
      this->matchStrArr->push_back(l);
    }
  }else{
    set<int> fset;
    for(auto it=this->filter->cbegin(); it!=this->filter->cend(); ++it) fset.insert(*it);
#ifdef USE_PCRE_REGEX
    jp::Regex reg (*(this->delim));
#else
    regex reg(*(this->delim));
#endif
    for(int i=this->matchStrArr->size(); i<this->catArr->size(); i++) {
      vector<string> elems = stringSplit(this->catArr->at(i), reg);
      string out = "";
      for(int j=0; j<elems.size(); j++) {
        if(fset.count(j) > 0) {
          out = out + elems.at(j);
        }else continue;
      }
      if (this->caseInsensitive == 1) out = lowercase(out);
      this->matchStrArr->push_back(out);
    }
  }

  *(this->readerStatus) = 1;
  *(this->syncStatus) = 1;
}
