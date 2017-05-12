<?php
/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

class BlobExpiredException extends Exception {
}
class GeneralSecurityException extends Exception {
}

/**
 * This class provides basic binary blob encryption and decryption, for use with the security token
 * 
 */
class BasicBlobCrypter extends BlobCrypter {
  //FIXME make this compatible with the java's blobcrypter
  

  // Labels for key derivation
  private $CIPHER_KEY_LABEL = 0;
  private $HMAC_KEY_LABEL = 1;
  
  /** Key used for time stamp (in seconds) of data */
  public $TIMESTAMP_KEY = "t";
  
  /** minimum length of master key */
  public $MASTER_KEY_MIN_LEN = 16;
  
  /** allow three minutes for clock skew */
  private $CLOCK_SKEW_ALLOWANCE = 180;
  
  private $UTF8 = "UTF-8";
  
  protected $cipherKey;
  protected $hmacKey;
  protected $ivKey;

  public function __construct() {
    $this->cipherKey = Config::get('token_cipher_key');
    $this->hmacKey = Config::get('token_hmac_key');
    $this->ivKey = Config::get('token_iv_key');
  }

  /**
   * {@inheritDoc}
   */
  public function wrap(Array $in) {
    $encoded = $this->serializeAndTimestamp($in);
    if (! function_exists('mcrypt_module_open')) {
      throw new GeneralSecurityException("mcrypt_module_open function not exists");
    }
    
    $cipherText = mcrypt_cbc(MCRYPT_RIJNDAEL_128, $this->cipherKey, $encoded, MCRYPT_ENCRYPT, $this->ivKey);
    $hmac = hash_hmac('sha1', $cipherText, $this->hmacKey, 1);
    $b64 = base64_encode($cipherText . $hmac);
    return $b64;
  }

  private function serializeAndTimestamp(Array $in) {
    $encoded = "";
    foreach ($in as $key => $val) {
      $encoded .= urlencode($key) . "=" . urlencode($val) . "&";
    }
    $encoded .= $this->TIMESTAMP_KEY . "=" . time();
    return $encoded;
  }

  /**
   * {@inheritDoc}
   */
  public function unwrap($in, $maxAgeSec) {
    $bin = base64_decode($in);
    if (is_callable('mb_substr')) {
      $cipherText = mb_substr($bin, 0, - 20, 'latin1');
      $hmac = mb_substr($bin, mb_strlen($cipherText, 'latin1'), 20, 'latin1');
    } else {
      $cipherText = substr($bin, 0, - 20);
      $hmac = substr($bin, strlen($cipherText));
    }
    
    $hmac_to_verified = hash_hmac('sha1', $cipherText, $this->hmacKey, 1);
    if ($hmac_to_verified != $hmac) {
      throw new GeneralSecurityException("HMAC verification failure");
    }

    $plain = mcrypt_cbc(MCRYPT_RIJNDAEL_128, $this->cipherKey, $cipherText, MCRYPT_DECRYPT, $this->ivKey);
    $out = $this->deserialize($plain);
    $this->checkTimestamp($out, $maxAgeSec);

    return $out;
  }

  private function deserialize($plain) {
    $map = array();
    $items = split("[&=]", $plain);
    for ($i = 0; $i < count($items);) {
      $key = urldecode($items[$i ++]);
      $value = urldecode($items[$i ++]);
      $map[$key] = $value;
    }
    return $map;
  }

  private function checkTimestamp(Array $out, $maxAge) {
    $minTime = (int)$out[$this->TIMESTAMP_KEY] - $this->CLOCK_SKEW_ALLOWANCE;
    $maxTime = (int)$out[$this->TIMESTAMP_KEY] + $maxAge + $this->CLOCK_SKEW_ALLOWANCE;
    $now = time();
    if (! ($minTime < $now && $now < $maxTime)) {
      throw new BlobExpiredException("Security token expired");
    }
  }
}
