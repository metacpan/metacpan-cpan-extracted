#ifndef _algo_h_
#define _algo_h_

#include <string>
#include <vector>
#include <unordered_map>
#include <regex>
#include <mutex>

extern "C" {
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "perlio.h"
#include "XSUB.h"
}

#define DEBUG
#ifdef DEBUG
#define DBGprint(...) printf(__VA_ARGS__)
#else
#define DBGprint(...)
#endif

#ifdef USE_PCRE_REGEX
// #include "pcre++.h"
// using namespace pcrepp;
#include "jpcre2.hpp"

typedef jpcre2::select<char> jp;
#endif

struct MatchResult{
  int line;
  int score;
  int sections;
  int* start_and_end;
  // int sections;
};

typedef struct MatchResult match_result_t;

struct HashResult{
  int matchNum;
  match_result_t * results;
};

typedef struct HashResult hash_result_t;

struct ThreadTask{
  std::vector<std::string>* matchStrArr;
  std::string patt;
  // int caseInsensitive;
  int algoType;
  std::vector<int> no; //避免stack内存溢出
  std::vector<int> index;
  int tid;
  match_result_t * results;
  int nth;
  std::string* delim;
  std::vector<int>* filter;
  std::vector<std::string>* catArr;
};
typedef struct ThreadTask thr_task_t;

struct InputTask{
  PerlIO* fileH;
  std::vector<std::string>* catArr;
  std::mutex* mtx;
  int* readerStatus;
  int* exitSign;
  int* maxLen;
  int headerLines;
  std::vector<std::string>* headerArr;
  std::mutex* headerMutex;
  std::vector<unsigned short>* markList;
};
typedef struct InputTask input_task_t;
  
class AlgoCpp {
public:
  AlgoCpp(int tac, int caseInsensitive, int headerLines);
  AlgoCpp(int tac, int caseInsensitive, int headerLines, int nth, char* delim, AV* filter);
  ~AlgoCpp();
  AlgoCpp() {}

  AV* matchList(const char* patt, int isSort, int caseInsensitive, int algoType, int THRS);
  void test();
  // void renewArray(AV* perlArr);
  void read(AV* perlArr);
  void asynRead(PerlIO* fileH);
  void asynLock();
  void asynUnLock();
  int getReaderStatus();
  void sendExitSign() ;
  SV* getStr(int index) ;
  int getCatArraySize() ;
  AV* getNullMatchList() ;
  AV* getHeaderStr() ;
  int getMaxLength();
  void setMarkLabel(int id);
  void setAllMarkLabel();
  void unSetMarkLabel(int id);
  void unSetAllMarkLabel();
  void toggleMarkLabel(int id);
  void toggleAllMarkLabel();
  AV* getMarkedStr();
  int getMarkLable(int id);
  int getMarkedCount();
  void clearMatchResult();
  static std::vector<int> matchRegex(const std::string seq, std::string patt);
  // static std::vector<int> matchPcre(const std::string seq, std::string patt);
  static std::vector<int> matchExact(const std::string seq, std::string patt); 
  static std::vector<int> matchV2(const std::string seq, std::string patt);
  static std::vector<int> matchV1(const std::string seq, std::string patt);

private:
  std::vector<std::string>* matchStrArr;
  std::vector<std::string>* catArr;
  std::vector<std::string>* headerArr;
  std::vector<unsigned short>* markList;
  std::mutex* arrMutex;
  std::mutex* headerMutex;
  int* readerStatus;
  int* syncStatus;
  int* exitSign;
  std::unordered_map<std::string, hash_result_t> resultsMap;
  int currAlgoType;
  int caseInsensitive;
  int tac;
  int nth=0;
  int headerLines;
  std::string* delim;
  std::vector<int>* filter;
  int* maxLen;

  static int getBelong(const std::vector<std::string> tokens, const std::vector<int> filter, int loc);
  static void fixNTHLoc(const std::string matchStr, const std::string delim, const std::vector<int> filter, int* start_and_end, int sections);
#ifdef USE_PCRE_REGEX
  static std::vector<std::string> stringSplit(const std::string& seq, jp::Regex& reg);
#else
  static std::vector<std::string> stringSplit(const std::string& str, std::regex& reg);
#endif
  // static std::vector<std::string> stringSplit(const std::string& str, const std::string delim);
  // static std::vector<std::string> stringSplitPcre(const std::string& seq, const std::string delim);

  static void work(thr_task_t task);
  static std::string lowercase(std::string str);
  // static void lowercase2(const char * src, char * dst);
  static bool compare_with_sections(match_result_t &a, match_result_t &b);
  static bool compare_with_sections_tac(match_result_t &a, match_result_t &b);
  static bool compare_with_score(match_result_t &a, match_result_t &b);
  static bool compare_with_score_tac(match_result_t &a, match_result_t &b);
  // static void getInput(PerlIO* fileH, std::vector<std::string>* catArr, std::mutex* mtx, int* status, int* maxLen, int headerLines, std::vector<std::string>* headerArr, std::mutex* headerMutex);
  static void getInput(input_task_t task);
  static void syncMatchArr(std::vector<std::string>* catArr, std::vector<std::string>* matchStrArr, std::mutex* mtx, int* readerStatus, int* syncStatus, int* exitSign, int caseInsensitive);
  static void syncMatchArrNTH(std::vector<std::string>* catArr, std::vector<std::string>* matchStrArr, std::mutex* mtx, int* readerStatus, int* syncStatus, int* exitSign, int caseInsensitive, std::string* delim, std::vector<int>* filter);
};


#endif

