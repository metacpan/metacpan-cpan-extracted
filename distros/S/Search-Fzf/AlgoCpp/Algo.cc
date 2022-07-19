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

#define M0(i,j) matrix[(i)*seqLen*2 + (j)*2 + 0]
#define M1(i,j) matrix[(i)*seqLen*2 + (j)*2 + 1]
#define MATCH       16 
#define MISMATCH  (-3)
#define GAP        (-1)
// #define MATCH       32 
// #define MISMATCH  (-32)
// #define GAP        (-1)

bool AlgoCpp::compare_with_sections(match_result_t &a, match_result_t &b){
    int sections_a = a.sections;
    int sections_b = b.sections;
    return sections_a > sections_b;
}
bool AlgoCpp::compare_with_sections_tac(match_result_t &a, match_result_t &b){
    int sections_a = a.sections;
    int sections_b = b.sections;
    return sections_a < sections_b;
}

bool AlgoCpp::compare_with_score(match_result_t &a, match_result_t &b){
    int score_a = a.score;
    int score_b = b.score;
    return score_a > score_b;
}

bool AlgoCpp::compare_with_score_tac(match_result_t &a, match_result_t &b){
    int score_a = a.score;
    int score_b = b.score;
    return score_a < score_b;
}
// void AlgoCpp::lowercase2(const char * src, char* dst) {
//   size_t len = strlen(src);
//   strcpy(dst, src);
//   for(int i=0;i<len;i++) dst[i] = tolower(dst[i]);
//   return;
// }
string AlgoCpp::lowercase(const string str) {
    char * buff = (char *)str.c_str();
    for(int i=0;i<str.length();i++) buff[i] = tolower(buff[i]);
    string destStr = buff;
    return destStr;
}


vector<int> AlgoCpp::matchV1(const string seq, string patt) { 
  int seqLen = seq.size();
  int pattLen = patt.size();

  int first = seq.find(patt.at(0));
  int last = seq.find_last_of(patt.at(pattLen-1), seqLen);

  int i;
  int j = pattLen - 1;
  int sumc = 0;
  vector<int> locVec;
  if ((first != string::npos) && (last != string::npos) && (last >= first)) {

    int k = last-first+1;
    vector<char> alignPatt(k, '\0');
    for (i=0; i<k ;i++) alignPatt[i] = '\0';
    for(i=last; i>=first; i--) {
      if (seq.at(i) == patt.at(j)) {
        alignPatt[i-first] = patt.at(j);
        sumc ++;
        j--;
        if(j<0) {
          alignPatt.erase(alignPatt.begin(), alignPatt.begin()+i-first);
          first = i;
          break;
        }
      }
      else{
        alignPatt[i-first] = '\0';
      }
    }

    k = last-first+1;
    // DBGprint("alginPatt[0] = %d, alginPatt[1] = %d, alginPatt[2] = %d\n", alignPatt[0], alignPatt[1], alignPatt[2]);

    if (sumc ==  pattLen){
      int status = 0;
      int charIndex = 0;
      int sc1=0, sc2=0;
      // char* buff = (char *)calloc(k, sizeof(char));
      for (i=0; i<k; i++) {
        if(alignPatt[i] == '\0') {
          sc1++;
          if (status == 1) {
            status = 0;
            sc2++;
            // memcpy(buff, alignPatt+charIndex, 1); //i-charIndex);
            // buff[i-charIndex] ='\0';
            locVec.push_back(first+charIndex);
            locVec.push_back(first+i);
          }
        }else{ //!='\0'
          if (status == 0) {
            charIndex = i;
            status = 1;
          }
        }
      }
      if (status == 1) {
        status = 0;
        sc2++;
        // memcpy(buff, alignPatt+charIndex, i-charIndex);
        // buff[i-charIndex] ='\0';
        locVec.push_back(first+charIndex);
        locVec.push_back(first+i);
      }
      int sc3 = seqLen - k;
      locVec.push_back(-(sc1+1)*(sc2)*(sc3*0.5)); //score
    }
  }

  return locVec;
}

vector<int> AlgoCpp::matchV2(const string seq, string patt) {
  int seqLen = seq.size();
  int pattLen =patt.size();

  int i, j, k;
  short *matrix = (short *)calloc((pattLen+1)*(seqLen+1)*2, sizeof(short));
  M0(0,0) = 0;
  M1(0,0) = 0;
  for(j = 1; j <= seqLen; j++) {
      M0(0,j) = 0;
      M1(0,j) = 0;
  }
  for (i = 1; i <= pattLen; i++) {
      M0(i,0) = 0;
      M1(i,0) = 0;
  }

  int diagonal_score, up_score, left_score;
  int max_i = 0;
  int max_j = 0;
  int max_score = 0;
  for(i=1; i<=pattLen; i++) {
    for(j=1; j<=seqLen; j++) {
      char letter1 = seq.at(j-1);
      char letter2 = patt.at(i-1);
      if (letter1 == letter2) {
        diagonal_score = M0(i-1,j-1) + MATCH;
      }else {
        diagonal_score = M0(i-1,j-1) + MISMATCH;
      }

      up_score = M0(i-1,j) + GAP;
      left_score = M0(i,j-1) + GAP;

      /*none=0 diagonal=1 left=2 up =3 */
      if (diagonal_score <= 0 && up_score <=0 && left_score <=0) {
         M0(i,j) = 0;
         M1(i,j) = 0;
         continue;
      }

      // choose best score
      if (diagonal_score >= up_score) {
          if (diagonal_score >= left_score) {
              M0(i,j)  = diagonal_score;
              M1(i,j) = 1;
          }
          else {
              M0(i,j)   = left_score;
              M1(i,j) = 2;
          }
      } else {
          if (up_score >= left_score) {
              M0(i,j)   = up_score;
              M1(i,j) = 3;
          }
          else {
              M0(i,j)   = left_score;
              M1(i,j) = 2;
          }
      }
      
      //set maximum score
      if (M0(i,j) > max_score) {
          max_i     = i;
          max_j     = j;
          max_score = M0(i,j);
      }
    }
  }

  // char* buff = (char *)calloc(seqLen, sizeof(char));
  vector<char> buff(seqLen, '\0');

  j = max_j;
  i = max_i;
  k = 0;

  int startIndex;
  int notFull = 0;
  //计算对齐字符串, 未匹配位置使用\0字符表示
  while (j >=0) {
      //last if $matrix[$i][$j]{pointer} eq "none";
      if(M1(i,j) == 0) {
        startIndex = j;
        break;
      }

      if (M1(i,j) == 1) {
          //align1 = strncat(align1, seq+j-1, 1);
          buff[k] = patt[i-1];
          i--;
          j--;
          k++;
      }else if (M1(i,j) == 2){
        //align1 = strncat(align1, seq+j-1, 1);
        buff[k] = '\0';
        j--;
        k++;
      }else if (M1(i,j) == 3) {
        //align1 = strcat(align1, "-");
        buff[k] = patt[i-1];
        i--;
        k++;
        notFull  = 1;
        break;
      }
  }
  free(matrix);

  vector<int> locVec;
  if (notFull == 1)  return locVec; 
  // free(buff);

  // char* alignPatt = (char *)calloc(k, sizeof(char));
  vector<char> alignPatt(k, '\0');
  int sumc = 0;

  for (i=0; i<k;i++) {
    alignPatt[i] = buff[k-i-1];
    if (alignPatt[i] != '\0') {
      sumc ++;
    }
  }

  if (sumc < pattLen)  return locVec; 

  int status = 0;
  int charIndex = 0;
  int sc1=0, sc2=0;
  for (i=0; i<k; i++) {
    if(alignPatt[i] == '\0') {
      sc1++;
      if (status == 1) {
        status = 0;
        sc2++;
        locVec.push_back(startIndex + charIndex);
        locVec.push_back(startIndex + i);
      }
    }else{ //!='\0'
      if (status == 0) {
        charIndex = i;
        status = 1;
      }
    }
  }
  if (status == 1) {
    status = 0;
    sc2++;
    locVec.push_back(startIndex + charIndex);
    locVec.push_back(startIndex + i);
  }
  int sc3 = seqLen - k;
  locVec.push_back(-(sc1+1)*(sc2)*(sc3*0.5)); //score
  return locVec;
}

vector<int> AlgoCpp::matchExact(const string seq, string patt){ 
  vector<int> locVec; 
  int ptr = seq.find(patt);
  if (ptr != string::npos) {
      int pattLen = patt.size();
      locVec.push_back(ptr);
      locVec.push_back(ptr + pattLen);
      locVec.push_back(-seq.size()); //score
  }
  return locVec;
}

#ifdef USE_PCRE_REGEX
// vector<int> AlgoCpp::matchRegex(const string seq, string patt){
//   Pcre reg(patt, "");
//   vector<int> locVec;
//   if(reg.search(seq) == true) {
//     locVec.push_back(reg.get_match_start());
//     locVec.push_back(reg.get_match_end()+1);
//     locVec.push_back(0);
//   }
//   return locVec;
// }
vector<int> AlgoCpp::matchRegex(const string seq, string patt){
  jp::VecNum vec_num;   //Vector to store numbered substring vectors.
  jp::Regex re (patt);
  jp::RegexMatch rm;
  rm.setRegexObject(&re)                        //set associated Regex object
    .setNumberedSubstringVector(&vec_num);       //pointer to numbered substring vector
  size_t matched = rm.setSubject(seq).addModifier("g").match();                                   //Now perform the match

  vector<int> locVec;
  if(matched) {
    int index = seq.find(vec_num[0][0], 0);
    locVec.push_back(index);
    locVec.push_back(index + vec_num[0][0].size());
    locVec.push_back(0);
  }
  return locVec;
}
#else
vector<int> AlgoCpp::matchRegex(const string seq, string patt){
  std::smatch m;
  std::regex e (patt);
  vector<int> locVec;
  string::const_iterator pos = seq.begin();
  string::const_iterator end = seq.end();
  if (regex_search(pos, end, m, e)) {
    // DBGprint("m.position(0)=%d\n", m.position(0));
    locVec.push_back(m.position(0));
    int &&end = m.position(0) + m.str().size();
    locVec.push_back(end);
    locVec.push_back(0);
  }
  return locVec;
}
#endif


int AlgoCpp::getBelong(const vector<string> tokens, const vector<int> filter, int loc) {
  int sumLen=0;
  for(auto it = filter.cbegin(); it != filter.cend(); ++it) {
    sumLen += tokens[*it].size();
    if (sumLen > loc)  return *it; 
  }
  return -1;
}
void AlgoCpp::fixNTHLoc(const string matchStr, const string delim, const vector<int> filter, int* start_and_end, int sections){
  set<int> fset (filter.begin(), filter.end());
  // vector<int> copy_v = start_and_end;
  int * copy_v = new int[sections];
  for(int i=0; i<sections; i++) copy_v[i] = start_and_end[i];

#ifdef USE_PCRE_REGEX
    jp::Regex reg (delim);
#else
    regex reg(delim);
#endif
  vector<string> tokens = stringSplit(matchStr, reg);
  for(int j=0; j<sections; j++){
    int belong = getBelong(tokens, filter, copy_v[j]);

    for(int i=0; i<tokens.size(); i++) {
      if (i<belong){
        if (fset.count(i) == 0) start_and_end[j] +=tokens[i].size();
      } else break;
    }
  }

  delete[] copy_v;
}

void AlgoCpp::work(thr_task_t task) {
  match_result_t * results = task.results;

  // Pcre reg(task.patt, "i");
  for(int i=0; i<task.no.size(); i++) {
    //执行匹配任务
    // DBGprint("%s\n", task.matchStrArr[task.no.at(i)].c_str());
    vector<int> locVec;
    if (task.algoType == 0) {
      locVec = move(matchExact(task.matchStrArr->at(task.no.at(i)), task.patt));
    }else if (task.algoType == 1) {
      locVec = move(matchV1(task.matchStrArr->at(task.no.at(i)), task.patt));
    }else if (task.algoType == 2) {
      locVec = move(matchV2(task.matchStrArr->at(task.no.at(i)), task.patt));
    } else if (task.algoType == 3) {
      locVec = move(matchRegex(task.matchStrArr->at(task.no.at(i)), task.patt));
    }

    //填装匹配结果
    results[task.index.at(i)].line = task.no.at(i);
    if (locVec.size() > 0) results[task.index.at(i)].sections = locVec.size() - 1;
    else results[task.index.at(i)].sections = 0;

    //匹配位置的起始和结束信息
    for(int k=0; k<results[task.index.at(i)].sections; k++) {
      results[task.index.at(i)].start_and_end[k] = locVec[k];
    }
    //匹配得分
    if (results[task.index.at(i)].sections > 0)
      results[task.index.at(i)].score = locVec.at(results[task.index.at(i)].sections);

    if(task.nth == 1) {
      if(results[task.index.at(i)].sections>0){
        // vector<int> locs (results[task.index.at(i)].start_and_end, results[task.index.at(i)].start_and_end +results[task.index.at(i)].sections);
        fixNTHLoc(task.catArr->at(task.no.at(i)), *task.delim, (*task.filter), results[task.index.at(i)].start_and_end, results[task.index.at(i)].sections);
        // for(int j=0; j<locs.size(); j++) results[task.index.at(i)].start_and_end[j] = locs[j];
      }
    }
  }
}


AV* AlgoCpp::matchList(const char* patt, int isSort, int caseInsensitive, int algoType, int THRS) {
  string pattStr;
  if (caseInsensitive == 1) {
    char* buff = new char[strlen(patt) + 1];
    strcpy(buff, patt);
    for(int i=0;i<strlen(patt);i++) buff[i] = tolower(buff[i]);
    pattStr = buff;
    delete []buff;
  }else{
    pattStr = patt;
  }

  int pattLen = pattStr.length();
  int matchNum;
  match_result_t * results;

  // DBGprint("Match array size is %d\n", this->matchStrArr->size());
  if (this->currAlgoType != algoType) {
    this->currAlgoType = algoType;
    this->resultsMap.clear();
  }
  if(this->resultsMap.count(pattStr) > 0){
    hash_result_t &hrt = this->resultsMap[pattStr];
    matchNum = hrt.matchNum;
    results = hrt.results;
  }else{
    int threshold = floor(this->matchStrArr->size()/3);
    THRS = THRS>threshold? threshold : THRS;
    THRS = THRS==0? 1 : THRS;


    //取得history列表
    vector<int> hisList;
    string pre_patt = pattStr.substr(0, pattStr.length()-1);
    int mrows;
    match_result_t* pre_results;
    if(this->resultsMap.count(pre_patt) > 0) {
      hash_result_t &phrt = this->resultsMap[pre_patt];
      mrows = phrt.matchNum;
      pre_results = phrt.results;
      for(int j=0; j< mrows; j++)  hisList.push_back(pre_results[j].line); 
    }else{
      //获得列表的切分
      for(int j =0; j<this->matchStrArr->size(); j++)  hisList.push_back(j); 
      mrows = this->matchStrArr->size();
    }

    //分区, 将输入的行数分解成为几个区, 分配给每个线程执行
    int div = floor((mrows*1.0)/(THRS*1.0));
    vector<int> part;
    int p = 0;
    for(int i=0;i<THRS;i++) {
      part.push_back(p);
      p += div;
    }
    part.push_back(mrows);
    
    vector<thr_task_t> tasks(THRS);
    vector<std::thread> threads(THRS);
    results = new match_result_t[mrows];
    //start_and_end, 存储匹配的起始和结束位置, 在堆上分配内存
    for(int i=0; i<mrows; i++) results[i].start_and_end = new int[pattLen*2*sizeof(int)];

    //启动多线程任务
    for (int i=0; i<THRS; i++) {
      tasks[i].tid = i;
      tasks[i].matchStrArr = this->matchStrArr;
      tasks[i].patt = pattStr;
      // tasks[i].caseInsensitive = caseInsensitive;
      tasks[i].algoType = algoType;
      tasks[i].results = results;
      if(this->nth == 1){
        tasks[i].nth = 1;
        tasks[i].delim = this->delim;
        tasks[i].filter = this->filter;
        tasks[i].catArr = this->catArr;
      }
      copy(hisList.cbegin()+part[i], hisList.cbegin()+part[i+1], back_inserter(tasks[i].no));
      for(int j=part[i]; j<part[i+1]; j++) tasks[i].index.push_back(j);
      threads[i] = std::thread(work, tasks[i]);
    }
    for (int i=0; i<THRS; i++)  threads[i].join(); 
    //线程后任务, 还原上次匹配任务的行号
    if(this->resultsMap.count(pre_patt) > 0) {
      for(int j=0; j<mrows; j++) results[j].line = pre_results[j].line;
    }

    //sort by sections
    if(this->tac == 0) {
      sort(results, results+mrows, compare_with_sections);
      matchNum=0;
      for(int j=0; j<mrows; j++) {
          if (results[j].sections > 0) matchNum++;
          if (results[j].sections == 0) break;
      }
      //缩小堆内存尺寸
      match_result_t* old_results = results;
      results = new match_result_t[matchNum];
      memcpy(results, old_results, matchNum*sizeof(match_result_t));
      for(int i=matchNum; i<mrows; i++) delete []old_results[i].start_and_end;
      delete [] old_results;
    }else {
      sort(results, results+mrows, compare_with_sections_tac);
      matchNum =0;
      for(int j=mrows-1; j>=0; j--) {
          if (results[j].sections > 0) matchNum++;
          if (results[j].sections == 0) break;
      }
      match_result_t* old_results = results;
      results = new match_result_t[matchNum];
      memcpy(results, old_results+mrows-matchNum, matchNum*sizeof(match_result_t));
      for(int i=mrows-matchNum-1; i>=0; i--) delete []old_results[i].start_and_end;
      delete [] old_results;
    }

    //根据匹配得分排序
    if (isSort == 1) {
      if (this->tac == 0) std::sort(results, results+matchNum, compare_with_score);
      else std::sort(results, results+matchNum, compare_with_score_tac);
    }

    //存入缓存
    hash_result_t hrt;
    hrt.matchNum = matchNum;
    hrt.results = results;
    this->resultsMap.insert(pair<string, hash_result_t>(patt, hrt));
  }

  AV* ret = newAV();
  if (this->tac == 0) {
    for(int j=0; j<matchNum; j++) {
        int sections = results[j].sections;
        int len = results[j].sections + 2;
        int* val = new int[len+1];
        val[0] = results[j].line;
        val[1] = results[j].score;
        for (int k=0; k<results[j].sections; k++) val[k+2] = results[j].start_and_end[k];
        char* val_c = (char *)val; 
        val_c[len*sizeof(int)] ='\0';
        av_push(ret, newSVpvn((const char *)val, len*sizeof(int)));
        delete []val;
    }
  }else {
    for(int j=matchNum-1; j>=0; j--) {
        int sections = results[j].sections;
        int len = results[j].sections + 2;
        int* val = new int[len+1];
        val[0] = results[j].line;
        val[1] = results[j].score;
        for (int k=0; k<results[j].sections; k++) val[k+2] = results[j].start_and_end[k];
        char* val_c = (char *)val;
        val_c[len*sizeof(int)] ='\0';
        av_push(ret, newSVpvn((const char *)val, len*sizeof(int)));
        delete []val;
    }
  }
  return ret;
}

AV* AlgoCpp::getNullMatchList() {
  AV* ret = newAV();
  if(this->tac == 0) {
    for(int i=0; i<this->matchStrArr->size(); i++) {
      int val[3];
      val[0] = i;
      val[1] = 0;
      char* val_c = (char *)val; 
      val_c[2*sizeof(int)] ='\0';
      av_push(ret, newSVpvn((const char *)val, 2*sizeof(int)));
    }
  }else{
    for(int i=this->matchStrArr->size() - 1; i>=0; i--) {
      int val[3];
      val[0] = i;
      val[1] = 0;
      char* val_c = (char *)val; 
      val_c[2*sizeof(int)] ='\0';
      av_push(ret, newSVpvn((const char *)val, 2*sizeof(int)));
    }
  }
  return ret;
}

AV* AlgoCpp::getHeaderStr() {
  AV* ret = newAV();
  std::lock_guard<std::mutex> lck(*(this->headerMutex));
  for(auto it=this->headerArr->cbegin(); it!=this->headerArr->cend(); ++it)
    av_push(ret, newSVpvn((*it).c_str(), (*it).size()));
  return ret;
}

int AlgoCpp::getMaxLength() {
  return *(this->maxLen);
}

void AlgoCpp::clearMatchResult() {
  this->resultsMap.clear();
}

void AlgoCpp::test() {
}

